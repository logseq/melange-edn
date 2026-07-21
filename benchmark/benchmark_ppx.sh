set -eu

element_count="${1:-10000}"

case "$element_count" in
  "" | *[!0-9]*)
    echo "Usage: sh benchmark/benchmark_ppx.sh [non-negative-element-count]" >&2
    exit 2
    ;;
esac

repository_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
temporary_directory=$(mktemp -d "${TMPDIR:-/tmp}/melange-edn-ppx-benchmark.XXXXXX")
source_file="$temporary_directory/large_literal.ml"

cleanup() {
  rm -rf "$temporary_directory"
}

trap cleanup EXIT HUP INT TERM

{
  printf 'let value : Melange_edn.any =\n  [%%edn {|['
  index=0
  while [ "$index" -lt "$element_count" ]; do
    if [ "$index" -gt 0 ]; then
      printf ' '
    fi
    printf '%s' "$index"
    index=$((index + 1))
  done
  printf ']|}]\n'
} >"$source_file"

cd "$repository_root"
dune build test/test_ppx_driver.exe

echo "Expanding one vector containing $element_count integer literals"

case "$(uname -s)" in
  Darwin)
    /usr/bin/time -l _build/default/test/test_ppx_driver.exe -null -impl "$source_file"
    ;;
  *)
    /usr/bin/time -v _build/default/test/test_ppx_driver.exe -null -impl "$source_file"
    ;;
esac
