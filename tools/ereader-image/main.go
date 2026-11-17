// Command ereader-image serves a Dutch verb of the day as a grayscale PNG sized
// for a KOReader sleep screen. The e-reader downloads
// http://<this computer>:8080/<secret word>/dashboard.png?width=1072&height=1448,
// and `ereader-image address` prints the server address to type on the e-reader.
package main

import (
	"bytes"
	"cmp"
	"crypto/rand"
	_ "embed"
	"encoding/csv"
	"fmt"
	"image"
	"image/color"
	"image/draw"
	"image/png"
	"log"
	"net"
	"net/http"
	"os"
	"os/exec"
	"strconv"
	"strings"
	"time"

	"golang.org/x/image/font"
	"golang.org/x/image/font/gofont/gobold"
	"golang.org/x/image/font/gofont/goregular"
	"golang.org/x/image/font/opentype"
	"golang.org/x/image/math/fixed"
)

const (
	port = "8080"
	// keychainItem names the Keychain item that holds the secret word.
	keychainItem = "ereader-image"
)

const (
	black     uint8 = 0
	gray      uint8 = 90
	lightGray uint8 = 170
)

var (
	regularFont, _ = opentype.Parse(goregular.TTF)
	boldFont, _    = opentype.Parse(gobold.TTF)
)

// Verb holds everything the card shows for one verb.
// Jij and Hij are empty when the form is the ik form plus t, and Wij when it is the infinitive.
// Participle is empty for a verb without a perfect tense.
type Verb struct {
	Infinitive, English, Ik, Jij, Hij, Wij, PastSingular, PastPlural, Participle, Helper, ExampleNL, ExampleEN string
}

//go:embed verbs.csv
var verbsCSV []byte

// verbs come from verbs.csv: a header row, then one verb per row with the columns in the order of the Verb fields.
var verbs = readVerbs(verbsCSV)

func readVerbs(data []byte) []Verb {
	rows, err := csv.NewReader(bytes.NewReader(data)).ReadAll()
	if err != nil {
		panic(err)
	}
	verbs := make([]Verb, 0, len(rows)-1)
	for _, r := range rows[1:] {
		verbs = append(verbs, Verb{r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10], r[11]})
	}
	return verbs
}

// Tense is a tense name with pronoun and form pairs, drawn two pairs per row.
type Tense struct {
	Name  string
	Pairs [][2]string
}

func (v Verb) Tenses() []Tense {
	regular := v.Ik
	if !strings.HasSuffix(regular, "t") {
		regular += "t"
	}
	jij, hij, wij := cmp.Or(v.Jij, regular), cmp.Or(v.Hij, regular), cmp.Or(v.Wij, v.Infinitive)
	tenses := []Tense{
		{"Present", [][2]string{{"ik", v.Ik}, {"wij", wij}, {"jij", jij}, {"jullie", wij}, {"hij/zij", hij}, {"zij", wij}}},
		{"Past", [][2]string{{"ik", v.PastSingular}, {"wij", v.PastPlural}}},
	}
	if v.Participle == "" {
		return tenses
	}
	return append(tenses, Tense{"Perfect", [][2]string{{"ik", v.Helper + " " + v.Participle}}})
}

func (v Verb) Card(width, height int, now time.Time) *image.Gray {
	c := NewCard(width, height)
	c.corner("updated " + now.Format("02 Jan 15:04"))
	c.label("Dutch verb")
	c.gap(1)
	c.line(v.Infinitive, 12, black, true)
	c.wrapped(v.English, 4.6, gray)
	c.rule()
	for i, tense := range v.Tenses() {
		if i > 0 {
			c.gap(2.5)
		}
		c.tense(tense)
	}
	c.rule()
	c.label("Example")
	c.wrapped(v.ExampleNL, 5.2, black)
	c.gap(0.5)
	c.wrapped(v.ExampleEN, 4.2, gray)
	return c.img
}

// Card is a grayscale canvas that lays out text from top to bottom.
// Sizes are in units of 1% of the width, capped so a wide screen doesn't overflow.
type Card struct {
	img         *image.Gray
	unit        float64
	left, right int
	y           int
}

func NewCard(width, height int) *Card {
	img := image.NewGray(image.Rect(0, 0, width, height))
	draw.Draw(img, img.Bounds(), image.White, image.Point{}, draw.Src)
	unit := min(float64(width), float64(height)*0.74) / 100
	left := int(unit * 8)
	return &Card{img: img, unit: unit, left: left, right: width - left, y: left}
}

func (c *Card) face(units float64, bold bool) font.Face {
	parsed := regularFont
	if bold {
		parsed = boldFont
	}
	face, _ := opentype.NewFace(parsed, &opentype.FaceOptions{Size: units * c.unit, DPI: 72, Hinting: font.HintingFull})
	return face
}

// draw writes text with its top at the current y.
func (c *Card) draw(x int, text string, units float64, shade uint8, bold bool) {
	face := c.face(units, bold)
	drawer := font.Drawer{
		Dst:  c.img,
		Src:  image.NewUniform(color.Gray{shade}),
		Face: face,
		Dot:  fixed.P(x, c.y).Add(fixed.Point26_6{Y: face.Metrics().Ascent}),
	}
	drawer.DrawString(text)
}

func (c *Card) gap(units float64) {
	c.y += int(units * c.unit)
}

func (c *Card) line(text string, units float64, shade uint8, bold bool) {
	c.draw(c.left, text, units, shade, bold)
	c.gap(units * 1.3)
}

func (c *Card) label(text string) {
	c.line(strings.ToUpper(text), 2.8, gray, true)
	c.gap(0.6)
}

// corner draws small gray text in the top right corner.
func (c *Card) corner(text string) {
	width := font.MeasureString(c.face(2.8, false), text).Ceil()
	c.draw(c.right-width, text, 2.8, gray, false)
}

// wrapped draws text over as many lines as it needs to fit the width.
func (c *Card) wrapped(text string, units float64, shade uint8) {
	face := c.face(units, false)
	line := ""
	for _, word := range strings.Fields(text) {
		longer := strings.TrimSpace(line + " " + word)
		if line != "" && font.MeasureString(face, longer).Ceil() > c.right-c.left {
			c.line(line, units, shade, false)
			longer = word
		}
		line = longer
	}
	c.line(line, units, shade, false)
}

func (c *Card) rule() {
	c.gap(3.5)
	thickness := max(1, int(c.unit*0.25))
	draw.Draw(c.img, image.Rect(c.left, c.y, c.right, c.y+thickness), image.NewUniform(color.Gray{lightGray}), image.Point{}, draw.Src)
	c.gap(3.5)
}

// tense draws the tense name and its pairs in two columns, gray pronoun then bold form.
func (c *Card) tense(tense Tense) {
	const units = 4.0
	c.label(tense.Name)
	indent := font.MeasureString(c.face(units, false), "hij/zij").Ceil() + int(units*c.unit*0.8)
	for i, pair := range tense.Pairs {
		x := c.left + i%2*(c.right-c.left)/2
		c.draw(x, pair[0], units, gray, false)
		c.draw(x+indent, pair[1], units, black, true)
		if i%2 == 1 || i == len(tense.Pairs)-1 {
			c.gap(units * 1.45)
		}
	}
}

// verbOfTheDay goes through the verbs in order, one per calendar day.
func verbOfTheDay(now time.Time) Verb {
	day := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, time.UTC).Unix() / (24 * 60 * 60)
	return verbs[day%int64(len(verbs))]
}

func serveCard(w http.ResponseWriter, r *http.Request) {
	width, _ := strconv.Atoi(r.URL.Query().Get("width"))
	height, _ := strconv.Atoi(r.URL.Query().Get("height"))
	now := time.Now()
	var body bytes.Buffer
	png.Encode(&body, verbOfTheDay(now).Card(cmp.Or(width, 1072), cmp.Or(height, 1448), now))
	w.Header().Set("Content-Type", "image/png")
	w.Header().Set("Content-Length", strconv.Itoa(body.Len()))
	w.Write(body.Bytes())
}

// secretWord returns the word the e-reader puts before /dashboard.png. The first
// time, it makes a random word of lowercase letters and saves it in the Keychain.
func secretWord() string {
	saved, err := exec.Command("security", "find-generic-password", "-s", keychainItem, "-w").Output()
	if err == nil {
		return strings.TrimSpace(string(saved))
	}
	word := make([]byte, 8)
	rand.Read(word)
	for i := range word {
		word[i] = 'a' + word[i]%26
	}
	err = exec.Command("security", "add-generic-password", "-s", keychainItem, "-a", keychainItem, "-w", string(word)).Run()
	if err != nil {
		log.Fatalf("could not save the secret word in the Keychain: %v", err)
	}
	return string(word)
}

// koboAddress is what to type as the server address on the e-reader: this
// computer's address on the local network, the port and the secret word.
func koboAddress(word string) string {
	// Dialing UDP sends nothing, it only picks the network this computer would use.
	conn, err := net.Dial("udp", "192.0.2.1:80")
	if err != nil {
		log.Fatalf("could not find this computer's network address: %v", err)
	}
	defer conn.Close()
	return fmt.Sprintf("%s:%s/%s", conn.LocalAddr().(*net.UDPAddr).IP, port, word)
}

func main() {
	word := secretWord()
	if len(os.Args) > 1 && os.Args[1] == "address" {
		fmt.Println(koboAddress(word))
		return
	}
	http.HandleFunc("GET /"+word+"/dashboard.png", serveCard)
	log.Print("Serving on port " + port + ", run `ereader-image address` for the e-reader's server address")
	log.Fatal(http.ListenAndServe(":"+port, nil))
}
