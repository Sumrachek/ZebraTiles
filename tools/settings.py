#!/usr/bin/env python3
"""Read and write the Connect IQ settings file on a sideloaded Edge.

Garmin Connect only exposes app settings for apps installed from the store, so
a sideloaded build is stuck with whatever defaults the device wrote into
Garmin/Apps/SETTINGS/<AppName>.SET. This edits that file directly, which beats
rebuilding and re-copying the .prg for every experiment.

    ./tools/settings.py                      show current values
    ./tools/settings.py ftp=250              change one
    ./tools/settings.py ftp=250 layout="3s_pwr; spd hr"

Deliberately not general: it knows the shapes this app uses, numbers and
strings, and nothing else.

File format, worked out from a device-written file:

    "abcdabcd"                  magic
    uint32                      byte length of the string blob
    string blob                 repeated: uint16 length, then that many bytes,
                                the last of which is a NUL
    "da7ada7a"                  magic
    uint32                      byte length of the value blob
    value blob                  repeated 5-byte records: uint8 type, uint32 value
                                0x0b dictionary, value = number of pairs
                                0x01 number,     value = the number itself
                                0x03 string,     value = offset into the blob
                                then 2 records per pair, key first

All integers are big-endian.
"""

import struct
import sys

DEVICE = "/Volumes/GARMIN/Garmin/Apps/SETTINGS/ZebraTiles.SET"

KEYS_MAGIC = b"\xab\xcd\xab\xcd"
VALUES_MAGIC = b"\xda\x7a\xda\x7a"
T_NUMBER, T_STRING, T_DICT = 0x01, 0x03, 0x0B


def read(path=DEVICE):
    """Returns {key: value}, insertion-ordered as stored."""
    blob = open(path, "rb").read()

    assert blob[0:4] == KEYS_MAGIC, "not a settings file"
    strings_len = struct.unpack(">I", blob[4:8])[0]
    strings = blob[8:8 + strings_len]

    at = 8 + strings_len
    assert blob[at:at + 4] == VALUES_MAGIC, "value blob not where expected"
    values_len = struct.unpack(">I", blob[at + 4:at + 8])[0]
    values = blob[at + 8:at + 8 + values_len]

    def string_at(offset):
        length = struct.unpack(">H", strings[offset:offset + 2])[0]
        return strings[offset + 2:offset + 2 + length - 1].decode("utf-8")

    def record(index):
        kind, value = struct.unpack(">BI", values[index * 5:index * 5 + 5])
        return kind, value

    kind, pairs = record(0)
    assert kind == T_DICT, f"expected a dictionary, got type {kind:#x}"

    out = {}
    for i in range(pairs):
        key_kind, key_ref = record(1 + i * 2)
        val_kind, val_ref = record(2 + i * 2)
        assert key_kind == T_STRING, "keys should be strings"
        key = string_at(key_ref)
        out[key] = val_ref if val_kind == T_NUMBER else string_at(val_ref)
    return out


def write(settings, path=DEVICE):
    """Rebuilds the file from {key: value}. Strings are interned in the order
    they are first met, which is what the device itself does."""
    strings = bytearray()
    offsets = {}

    def intern(text):
        if text not in offsets:
            encoded = text.encode("utf-8") + b"\x00"
            offsets[text] = len(strings)
            strings.extend(struct.pack(">H", len(encoded)) + encoded)
        return offsets[text]

    records = [struct.pack(">BI", T_DICT, len(settings))]
    for key, value in settings.items():
        records.append(struct.pack(">BI", T_STRING, intern(key)))
        if isinstance(value, int):
            records.append(struct.pack(">BI", T_NUMBER, value))
        else:
            records.append(struct.pack(">BI", T_STRING, intern(str(value))))

    values = b"".join(records)
    blob = (KEYS_MAGIC + struct.pack(">I", len(strings)) + bytes(strings)
            + VALUES_MAGIC + struct.pack(">I", len(values)) + values)
    open(path, "wb").write(blob)


def main(args):
    current = read()
    if not args:
        for key, value in current.items():
            shown = value if isinstance(value, int) else f'"{value}"'
            print(f"  {key:12} {shown}")
        return 0

    for arg in args:
        if "=" not in arg:
            print(f"expected key=value, got {arg!r}", file=sys.stderr)
            return 1
        key, _, raw = arg.partition("=")
        if key not in current:
            print(f"unknown setting {key!r}; have {', '.join(current)}", file=sys.stderr)
            return 1
        # The stored type decides how to read the argument - no guessing.
        current[key] = int(raw) if isinstance(current[key], int) else raw

    write(current)
    print("written; eject the volume before unplugging")
    for key, value in read().items():
        shown = value if isinstance(value, int) else f'"{value}"'
        print(f"  {key:12} {shown}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
