import Toybox.Lang;

//! One tile of the screen.
class Cell {
    public var code as Number;
    public var name as String;

    function initialize(token as String) {
        name = token.toUpper();
        code = Fields.codeFor(name);
    }
}

//! One horizontal band of tiles.
class Row {
    public var cells as Array<Cell>;
    public var isStatus as Boolean;

    function initialize(tokens as Array<String>, status as Boolean) {
        isStatus = status;
        cells = [] as Array<Cell>;
        for (var i = 0; i < tokens.size(); i++) {
            cells.add(new Cell(tokens[i]));
        }
    }
}

//! Turns the layout text into rows of tiles.
module Spec {

    //! Rows are separated by a newline or a semicolon, tiles by whitespace.
    function parse(text as String) as Array<Row> {
        var rows = [] as Array<Row>;
        var lines = splitOn(text, ['\n', ';', '\r'] as Array<Char>);

        for (var i = 0; i < lines.size(); i++) {
            var tokens = splitOn(lines[i], [' ', '\t'] as Array<Char>);
            if (tokens.size() == 0) {
                continue;
            }

            var status = false;
            if (tokens[0].equals("=")) {
                status = true;
                tokens = tokens.slice(1, null);
            }
            if (tokens.size() > 0 && tokens[tokens.size() - 1].equals("=")) {
                status = true;
                tokens = tokens.slice(0, tokens.size() - 1);
            }
            if (tokens.size() == 0) {
                continue;
            }
            rows.add(new Row(tokens, status));
        }

        if (rows.size() == 0) {
            rows.add(new Row(["?"] as Array<String>, false));
        }
        return rows;
    }

    function splitOn(text as String, seps as Array<Char>) as Array<String> {
        var out = [] as Array<String>;
        var chars = text.toCharArray();
        var cur = "";

        for (var i = 0; i < chars.size(); i++) {
            var c = chars[i];
            var isSep = false;
            for (var s = 0; s < seps.size(); s++) {
                if (c == seps[s]) {
                    isSep = true;
                    break;
                }
            }
            if (isSep) {
                if (cur.length() > 0) {
                    out.add(cur);
                    cur = "";
                }
            } else {
                cur += c.toString();
            }
        }
        if (cur.length() > 0) {
            out.add(cur);
        }
        return out;
    }
}
