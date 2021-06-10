-- Configuration for Xmobar, place this file at ~/.config/xmobar/xmobarcc
Config
  { font = "Dejavu Sans Mono:size=10",
    additionalFonts = [],
    borderColor = "black",
    border = TopB,
    bgColor = "black",
    fgColor = "grey",
    alpha = 255,
    position = Top,
    textOffset = -1,
    iconOffset = 0,
    lowerOnStart = True,
    pickBroadest = False,
    persistent = False,
    hideOnStart = False,
    iconRoot = ".",
    allDesktops = True,
    overrideRedirect = True,
    commands =
      [ Run StdinReader,
        Run
          Weather
          "EGPF"
          [ "-t",
            "<station>: <tempC>C",
            "-L",
            "18",
            "-H",
            "25",
            "--normal",
            "green",
            "--high",
            "red",
            "--low",
            "lightblue"
          ]
          36000,
        Run
          Network
          "wlp1s0"
          [ "-L",
            "0",
            "-H",
            "32",
            "--normal",
            "green",
            "--high",
            "red"
          ]
          10,
        Run
          Cpu
          [ "-L",
            "3",
            "-H",
            "50",
            "--normal",
            "green",
            "--high",
            "red"
          ]
          10,
        Run Memory ["-t", "Mem: <usedratio>%"] 10,
        Run Date "%a %b %_d %Y %H:%M" "date" 10,
        Run Alsa "default" "Master" [],
        Run
          BatteryP
          ["BAT0"]
          [ "-t",
            "<acstatus>",
            "-L",
            "10",
            "-H",
            "80",
            "-l",
            "red",
            "-h",
            "green",
            "--",
            "-O",
            "Charging: <left>%",
            "-o",
            "Battery: <left>%"
          ]
          10
      ],
    sepChar = "%",
    alignSep = "}{",
    template =
      " %StdinReader% }{ %cpu% & %memory% | %wlp1s0% |\
      \ %alsa:default:Master%| %battery% | <fc=#ee9a00>%date%</fc> "
  }
