set -eu

compiler="$1"
driver="$2"
shift 2

case "$driver" in
  /*) ;;
  *) driver="$PWD/$driver" ;;
esac

check_failure() {
  source_file="$1"
  expected_message="$2"
  output_file="${TMPDIR:-/tmp}/melange-edn-ppx-$(basename "$source_file").log"

  if "$compiler" -ppx "$driver --as-ppx" -c "$source_file" >"$output_file" 2>&1; then
    echo "Expected compilation to fail: $source_file" >&2
    exit 1
  fi

  if ! grep -F "$(basename "$source_file")" "$output_file" >/dev/null; then
    echo "Expected the error to point at $source_file" >&2
    cat "$output_file" >&2
    exit 1
  fi

  if ! grep -F "melange-edn-ppx: $expected_message" "$output_file" >/dev/null; then
    echo "Expected compile-time error was not reported for $source_file" >&2
    cat "$output_file" >&2
    exit 1
  fi
}

check_failure "$1" "EDN literal must contain exactly one form; found none"
check_failure "$2" "at position 6: missing closing }"
check_failure "$3" "EDN literal must contain exactly one form; found 2"
check_failure "$4" "extension payload must be a string literal"
