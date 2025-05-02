{
  # Shell script formatter
  shfmt = {
    enable = true;
    options = [
      "-i"
      "2" # indent 2
      "-s" # simplify the code
      "-w" # write back to the file
    ];
    includes = ["**/*.sh"];
    priority = 1; # Run first for shell files
  };
  
  # Shell script linter
  shellcheck = {
    enable = true;
    options = ["-s" "bash"];
    includes = ["**/*.sh"];
    priority = 2; # Run after shfmt
  };
}
