# Dots in a username become dashes in its flake attribute

`dan.avner` is built as `#dan-avner`. `darwin-rebuild` splits its `--flake ...#attr` argument on `.` and appends `.system`, so a dotted attribute is read as several path segments and never resolves. Any code that maps a username to a flake attribute applies the same substitution.
