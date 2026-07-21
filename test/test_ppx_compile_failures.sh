set -eu

compiler="$1"
driver="$2"
core_archive="$3"
core_directory="$(dirname "$core_archive")"
shift 3

case "$driver" in
  /*) ;;
  *) driver="$PWD/$driver" ;;
esac

compile() {
  source_file="$1"
  output_file="$2"

  "$compiler" -I "$core_directory" -ppx "$driver --as-ppx" -c "$source_file" \
    >"$output_file" 2>&1
}

check_ppx_failure() {
  source_file="$1"
  expected_message="$2"
  output_file="${TMPDIR:-/tmp}/melange-edn-ppx-$(basename "$source_file").log"

  if compile "$source_file" "$output_file"; then
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

check_compiler_failure() {
  source_file="$1"
  expected_message="$2"
  output_file="${TMPDIR:-/tmp}/melange-edn-ppx-$(basename "$source_file").log"

  if compile "$source_file" "$output_file"; then
    echo "Expected compilation to fail: $source_file" >&2
    exit 1
  fi

  if ! grep -F "$(basename "$source_file")" "$output_file" >/dev/null; then
    echo "Expected the error to point at $source_file" >&2
    cat "$output_file" >&2
    exit 1
  fi

  if ! grep -F "$expected_message" "$output_file" >/dev/null; then
    echo "Expected compiler error was not reported for $source_file" >&2
    cat "$output_file" >&2
    exit 1
  fi
}

check_ppx_failure "$1" "EDN literal must contain exactly one form; found none"
check_ppx_failure "$2" "at position 6: missing closing }"
check_ppx_failure "$3" "EDN literal must contain exactly one form; found 2"
check_ppx_failure "$4" "extension payload must be a string literal"
check_ppx_failure "$5" "invalid antiquotation identifier: ?"
check_ppx_failure "$6" "invalid antiquotation identifier: ?foo-bar"
check_ppx_failure "$7" "invalid antiquotation identifier: ?let"
check_ppx_failure "$8" "invalid antiquotation identifier: ?Module.value"
check_ppx_failure "$9" "invalid antiquotation identifier: ?foo/bar"
check_ppx_failure "${10}" "invalid antiquotation identifier: ?Foo"
check_compiler_failure "${11}" "Melange_edn.any"
check_compiler_failure "${12}" "Melange_edn.t"
check_compiler_failure "${13}" "Melange_edn.t"
check_compiler_failure "${14}" "Unbound value missing"
