// Command ereader-dashboard serves the weather in Amsterdam and a Dutch verb of
// the day as a grayscale PNG sized for a KOReader sleep screen. The e-reader downloads
// http://<this computer>:8080/<secret word>/dashboard.png?width=1072&height=1448,
// and `ereader-dashboard address` prints the server address to type on the e-reader.
package main

import (
	"bytes"
	"cmp"
	"crypto/rand"
	_ "embed"
	"encoding/csv"
	"encoding/json"
	"fmt"
	"image"
	"image/color"
	"image/draw"
	"image/png"
	"log"
	"math"
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
	keychainItem = "ereader-dashboard"
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
// The examples are sentences from tatoeba.org, shared under CC BY 2.0 FR, and the last
// column is each example's sentence number there.
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

// Place is a spot Buienradar has a forecast for. ID is the number at the end of
// the address of its Buienradar weather page.
type Place struct {
	Name     string
	ID       int
	Lat, Lon float64
}

var home = Place{Name: "Amsterdam", ID: 2759794, Lat: 52.37, Lon: 4.89}

const (
	// rainStep is the time between two points of the rain forecast.
	rainStep = 5 * time.Minute
	// rainAhead is how far ahead the rain chart looks.
	rainAhead = 2 * time.Hour
)

// Weather is the temperature in the coming hour and the rain in the next two hours.
type Weather struct {
	Temperature, FeelsLike float64
	Rain                   []Rain
	// Bands are the rain levels Buienradar calls light, moderate and heavy.
	Bands []float64
}

// Rain is the forecast for one five minute step. Level goes from 0 for dry to 100 for the heaviest rain.
type Rain struct {
	Time  time.Time
	Level float64
}

var buienradar = &http.Client{Timeout: 2 * time.Second}

func getJSON(url string, into any) error {
	resp, err := buienradar.Get(url)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("%s answered with %s", url, resp.Status)
	}
	return json.NewDecoder(resp.Body).Decode(into)
}

// FetchWeather gets the weather from the same addresses the Buienradar website uses.
func (p Place) FetchWeather(now time.Time) (Weather, error) {
	var rain struct {
		Borders []struct {
			PercentageValue float64
		}
		Forecasts []struct {
			UTCDateTime     string
			PercentageValue float64
		}
	}
	rainURL := fmt.Sprintf("https://graphdata.buienradar.nl/3.0/forecast/geo/RainHistoryForecast?lat=%.2f&lon=%.2f", p.Lat, p.Lon)
	if err := getJSON(rainURL, &rain); err != nil {
		return Weather{}, err
	}
	var forecast struct {
		Days []struct {
			Hours []struct {
				Temperature, FeelTemperature float64
			}
		}
	}
	if err := getJSON(fmt.Sprintf("https://forecast.buienradar.nl/2.0/forecast/%d", p.ID), &forecast); err != nil {
		return Weather{}, err
	}

	var weather Weather
	for _, border := range rain.Borders {
		weather.Bands = append(weather.Bands, border.PercentageValue)
	}
	for _, point := range rain.Forecasts {
		// The time has no zone, so Parse reads it as UTC, which it is.
		at, err := time.Parse("2006-01-02T15:04:05", point.UTCDateTime)
		if err != nil {
			return Weather{}, err
		}
		if at.After(now.Add(-rainStep)) && !at.After(now.Add(rainAhead)) {
			weather.Rain = append(weather.Rain, Rain{at, point.PercentageValue})
		}
	}
	// The first hour in the forecast is the coming hour.
	for _, day := range forecast.Days {
		if len(day.Hours) > 0 {
			weather.Temperature, weather.FeelsLike = day.Hours[0].Temperature, day.Hours[0].FeelTemperature
			return weather, nil
		}
	}
	return Weather{}, fmt.Errorf("the forecast for %s has no hours", p.Name)
}

// Dashboard is everything on the sleep screen picture.
type Dashboard struct {
	Weather Weather
	Verb    Verb
	Updated time.Time
}

// Image draws the dashboard, smaller than usual when it would not fit the height.
func (d Dashboard) Image(width, height int) *image.Gray {
	c := d.draw(width, height, 1)
	// The bottom margin is as wide as the side margins.
	if fit := float64(height) / float64(c.y+c.left); fit < 1 {
		c = d.draw(width, height, fit)
	}
	return c.img
}

func (d Dashboard) draw(width, height int, scale float64) *Card {
	c := NewCard(width, height, scale)
	c.weather(d.Weather, "updated "+d.Updated.Format("02 Jan 15:04"))
	c.rule()
	c.verb(d.Verb)
	return c
}

// Card is a grayscale canvas that lays out text from top to bottom.
// Sizes are in units of 1% of the width, capped so a wide screen doesn't overflow,
// and multiplied by the scale.
type Card struct {
	img         *image.Gray
	unit        float64
	left, right int
	y           int
}

func NewCard(width, height int, scale float64) *Card {
	img := image.NewGray(image.Rect(0, 0, width, height))
	draw.Draw(img, img.Bounds(), image.White, image.Point{}, draw.Src)
	unit := min(float64(width), float64(height)*0.74) / 100 * scale
	left := int(unit * 8)
	return &Card{img: img, unit: unit, left: left, right: width - left, y: left}
}

func (c *Card) px(units float64) int {
	return int(units * c.unit)
}

func (c *Card) face(units float64, bold bool) font.Face {
	parsed := regularFont
	if bold {
		parsed = boldFont
	}
	face, _ := opentype.NewFace(parsed, &opentype.FaceOptions{Size: units * c.unit, DPI: 72, Hinting: font.HintingFull})
	return face
}

func (c *Card) width(text string, units float64, bold bool) int {
	return font.MeasureString(c.face(units, bold), text).Ceil()
}

// ascent is how far text reaches above the line it sits on.
func (c *Card) ascent(units float64, bold bool) int {
	return c.face(units, bold).Metrics().Ascent.Ceil()
}

// text writes text with its top at y.
func (c *Card) text(x, y int, text string, units float64, shade uint8, bold bool) {
	face := c.face(units, bold)
	drawer := font.Drawer{
		Dst:  c.img,
		Src:  image.NewUniform(color.Gray{shade}),
		Face: face,
		Dot:  fixed.P(x, y).Add(fixed.Point26_6{Y: face.Metrics().Ascent}),
	}
	drawer.DrawString(text)
}

func (c *Card) fill(area image.Rectangle, shade uint8) {
	draw.Draw(c.img, area, image.NewUniform(color.Gray{shade}), image.Point{}, draw.Src)
}

func (c *Card) gap(units float64) {
	c.y += c.px(units)
}

func (c *Card) line(text string, units float64, shade uint8, bold bool) {
	c.text(c.left, c.y, text, units, shade, bold)
	c.gap(units * 1.3)
}

func (c *Card) label(text string) {
	c.line(strings.ToUpper(text), 2.8, gray, true)
	c.gap(0.6)
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

func (c *Card) thickness() int {
	return max(1, c.px(0.25))
}

func (c *Card) rule() {
	c.gap(3.5)
	c.fill(image.Rect(c.left, c.y, c.right, c.y+c.thickness()), lightGray)
	c.gap(3.5)
}

// weather draws the temperature and what it feels like on one line, with the
// note in gray on the right, and the rain chart below them.
func (c *Card) weather(w Weather, note string) {
	const units, smallUnits = 10.0, 2.8
	temperature := fmt.Sprintf("%d°", int(math.Round(w.Temperature)))
	feelsLike := fmt.Sprintf("feels like %d°", int(math.Round(w.FeelsLike)))
	baseline := c.y + c.ascent(units, true)
	small := baseline - c.ascent(smallUnits, false)
	c.text(c.left, c.y, temperature, units, black, true)
	c.text(c.left+c.width(temperature, units, true)+c.px(2), small, feelsLike, smallUnits, gray, false)
	c.text(c.right-c.width(note, smallUnits, false), small, note, smallUnits, gray, false)
	c.gap(units * 1.3)
	c.rainChart(w)
}

// rainChart draws one bar per forecast step across the width, light lines at
// the rain bands, and the time under every half hour.
func (c *Card) rainChart(w Weather) {
	const chartUnits, timeUnits = 9.0, 2.6
	top, bottom := c.y, c.y+c.px(chartUnits)
	levelY := func(level float64) int {
		return bottom - int(min(level, 100)/100*float64(bottom-top))
	}
	for _, band := range w.Bands {
		y := levelY(band)
		c.fill(image.Rect(c.left, y, c.right, y+1), lightGray)
	}
	step := float64(c.right-c.left) / float64(max(len(w.Rain), 1))
	for i, rain := range w.Rain {
		x := c.left + int(float64(i)*step)
		c.fill(image.Rect(x, levelY(rain.Level), x+int(step*0.75), bottom), black)
		at := rain.Time.Local()
		if at.Minute()%30 != 0 {
			continue
		}
		label := at.Format("15:04")
		center := x + int(step*0.375)
		labelX := min(max(center-c.width(label, timeUnits, false)/2, c.left), c.right-c.width(label, timeUnits, false))
		c.text(labelX, bottom+c.px(1), label, timeUnits, gray, false)
	}
	c.fill(image.Rect(c.left, bottom, c.right, bottom+c.thickness()), lightGray)
	c.y = bottom + c.px(1+timeUnits*1.3)
}

func (c *Card) verb(v Verb) {
	c.label("Dutch verb")
	c.gap(1)
	c.line(v.Infinitive, 8.5, black, true)
	c.wrapped(v.English, 3.8, gray)
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
}

// tense draws the tense name and its pairs in two columns, gray pronoun then bold form.
func (c *Card) tense(tense Tense) {
	const units = 4.0
	c.label(tense.Name)
	indent := c.width("hij/zij", units, false) + c.px(units*0.8)
	for i, pair := range tense.Pairs {
		x := c.left + i%2*(c.right-c.left)/2
		c.text(x, c.y, pair[0], units, gray, false)
		c.text(x+indent, c.y, pair[1], units, black, true)
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

func serveDashboard(w http.ResponseWriter, r *http.Request) {
	width, _ := strconv.Atoi(r.URL.Query().Get("width"))
	height, _ := strconv.Atoi(r.URL.Query().Get("height"))
	now := time.Now()
	weather, err := home.FetchWeather(now)
	if err != nil {
		log.Printf("could not get the weather: %v", err)
		http.Error(w, "could not get the weather", http.StatusBadGateway)
		return
	}
	dashboard := Dashboard{Weather: weather, Verb: verbOfTheDay(now), Updated: now}
	var body bytes.Buffer
	png.Encode(&body, dashboard.Image(cmp.Or(width, 1072), cmp.Or(height, 1448)))
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
	http.HandleFunc("GET /"+word+"/dashboard.png", serveDashboard)
	log.Print("Serving on port " + port + ", run `ereader-dashboard address` for the e-reader's server address")
	log.Fatal(http.ListenAndServe(":"+port, nil))
}
