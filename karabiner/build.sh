#!/bin/sh
# Writes every file in rules/ into karabiner.json as its own eval_js rule,
# keeping the enabled state you set in the Karabiner window.
# Files named *-layer.js get shared.js pasted in front of them.
set -e

dir=$(cd "$(dirname "$0")" && pwd)
cli="/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli"
config="$dir/karabiner.json"
profile="Generated Profile"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

rules='[]'

collect() {
	source=$1
	prelude=$2
	target="$work/$(basename "$source")"

	echo "// rule: $(basename "$source")" > "$target"
	if [ -n "$prelude" ]; then
		cat "$prelude" >> "$target"
	fi
	cat "$source" >> "$target"

	rules=$(printf '%s' "$rules" | jq --rawfile code "$target" '. + [{ eval_js: $code }]')
}

for source in "$dir"/rules/*.js; do
	case "$(basename "$source")" in
	shared.js) continue ;;
	*-layer.js) collect "$source" "$dir/rules/shared.js" ;;
	*) collect "$source" "" ;;
	esac
done

"$cli" --lint-complex-modifications "$work/*.js"

jq --argjson rules "$rules" --arg profile "$profile" '
	def marker: .eval_js | split("\n")[0];
	([ .profiles[] | select(.name == $profile) | .complex_modifications.rules[]?
	   | select(has("eval_js") and has("enabled"))
	   | { key: marker, value: .enabled } ] | from_entries) as $state
	| (.profiles[] | select(.name == $profile) | .complex_modifications.rules) =
		[ $rules[] | if $state[marker] == null then . else . + { enabled: $state[marker] } end ]
' "$config" > "$config.new"
mv "$config.new" "$config"

"$cli" --format-json "$config"

echo "wrote $(printf '%s' "$rules" | jq length) rules into $config"
