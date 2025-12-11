# scripts/inspect.nix
{ pkgs, pog }:

pog.pog {
  name = "inspect";
  version = "1.0.0";
  description = "Show contents of disk image or archive";

  arguments = [
    {
      name = "file";
      description = "disk image (.img) or archive (.tar.gz) to inspect";
    }
  ];
  argumentCompletion = "files";

  runtimeInputs = with pkgs; [
    squashfsTools
    gnutar
    gzip
    file
    coreutils
    tree
  ];

  script = helpers: ''
    FILE="$1"

    if ${helpers.var.empty "FILE"}; then
      die "Error: File required\nUsage: inspect <file>"
    fi

    if ${helpers.file.notExists "FILE"}; then
      die "Error: File not found: $FILE"
    fi

    green "=== File: $FILE ==="
    echo ""
    cyan "File info:"
    ls -lh "$FILE"
    echo ""
    cyan "Filesystem type:"
    file "$FILE"
    echo ""
    cyan "Contents:"
    echo ""

    # Detect file type and extract accordingly
    if file "$FILE" | grep -q "Squashfs"; then
      # SquashFS disk - extract and show contents
      TEMP_DIR=$(mktemp -d)
      unsquashfs -d "$TEMP_DIR/extracted" -no-progress "$FILE" > /dev/null 2>&1

      tree -a "$TEMP_DIR/extracted" 2>/dev/null || \
        (cd "$TEMP_DIR/extracted" && find . -print | sed -e 's;[^/]*/;|____;g;s;____|;  |;g')

      rm -rf "$TEMP_DIR"
    elif file "$FILE" | grep -q "gzip"; then
      # tar.gz archive - list contents with structure
      TEMP_DIR=$(mktemp -d)
      tar xzf "$FILE" -C "$TEMP_DIR" 2>/dev/null
      tree -a "$TEMP_DIR" 2>/dev/null || tar tzf "$FILE" | sed 's|^|  |'
      rm -rf "$TEMP_DIR"
    else
      die "Unknown file type"
    fi
  '';
}
