object GETDISPLAY: TGETDISPLAY
  Left = 192
  Top = 125
  AlphaBlend = True
  AlphaBlendValue = 200
  BorderStyle = bsNone
  Caption = 'GETDISPLAY'
  ClientHeight = 347
  ClientWidth = 451
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object ALAPPANEL: TPanel
    Left = 0
    Top = 0
    Width = 449
    Height = 345
    BevelOuter = bvNone
    Color = clActiveCaption
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Lemon'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
    object Shape1: TShape
      Left = 0
      Top = 0
      Width = 449
      Height = 345
      Align = alClient
      Brush.Color = clMoneyGreen
      Pen.Color = clRed
      Pen.Width = 5
    end
    object Label1: TLabel
      Left = 24
      Top = 24
      Width = 373
      Height = 24
      Caption = 'MELYIK ADATOKAT MUTASSAM MEG ?'
      Font.Charset = ANSI_CHARSET
      Font.Color = clTeal
      Font.Height = -21
      Font.Name = 'Lemon'
      Font.Style = []
      ParentFont = False
      Transparent = True
    end
    object MP1: TPanel
      Tag = 1
      Left = 48
      Top = 64
      Width = 353
      Height = 25
      Cursor = crHandPoint
      Caption = 'Id'#337'szaki forgalom'
      Color = clYellow
      Font.Charset = ANSI_CHARSET
      Font.Color = clRed
      Font.Height = -16
      Font.Name = 'Lemon'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      OnClick = MP8DblClick
      OnDblClick = MP8DblClick
      OnEnter = MP1Enter
      OnExit = MP1Exit
      OnMouseMove = MP1MouseMove
    end
    object MP8: TPanel
      Tag = 8
      Left = 48
      Top = 288
      Width = 353
      Height = 25
      Cursor = crHandPoint
      Caption = 'Kil'#233'p'#233's a programb'#243'l'
      Font.Charset = ANSI_CHARSET
      Font.Color = clGray
      Font.Height = -16
      Font.Name = 'Lemon'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
      OnClick = MP8DblClick
      OnDblClick = MP8DblClick
      OnEnter = MP1Enter
      OnExit = MP1Exit
      OnMouseMove = MP1MouseMove
    end
    object MP7: TPanel
      Tag = 7
      Left = 48
      Top = 256
      Width = 353
      Height = 25
      Cursor = crHandPoint
      Caption = 'Storn'#243'zott bizonylatok'
      Font.Charset = ANSI_CHARSET
      Font.Color = clGray
      Font.Height = -16
      Font.Name = 'Lemon'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
      OnClick = MP8DblClick
      OnDblClick = MP8DblClick
      OnEnter = MP1Enter
      OnExit = MP1Exit
      OnMouseMove = MP1MouseMove
    end
    object MP6: TPanel
      Tag = 6
      Left = 48
      Top = 224
      Width = 353
      Height = 25
      Cursor = crHandPoint
      Caption = 'TRB mozg'#225'sok list'#225'i'
      Font.Charset = ANSI_CHARSET
      Font.Color = clGray
      Font.Height = -16
      Font.Name = 'Lemon'
      Font.Style = []
      ParentFont = False
      TabOrder = 3
      OnClick = MP8DblClick
      OnDblClick = MP8DblClick
      OnEnter = MP1Enter
      OnExit = MP1Exit
      OnMouseMove = MP1MouseMove
    end
    object MP2: TPanel
      Tag = 2
      Left = 48
      Top = 96
      Width = 353
      Height = 25
      Cursor = crHandPoint
      Caption = 'Id'#337'szaki k'#233'szletek, cimletek '
      Font.Charset = ANSI_CHARSET
      Font.Color = clGray
      Font.Height = -16
      Font.Name = 'Lemon'
      Font.Style = []
      ParentFont = False
      TabOrder = 4
      OnClick = MP8DblClick
      OnDblClick = MP8DblClick
      OnEnter = MP1Enter
      OnExit = MP1Exit
      OnMouseMove = MP1MouseMove
    end
    object MP3: TPanel
      Tag = 3
      Left = 48
      Top = 128
      Width = 353
      Height = 25
      Cursor = crHandPoint
      Caption = 'Western Union '#233's AFA visszat'#233'rit'#233's'
      Font.Charset = ANSI_CHARSET
      Font.Color = clGray
      Font.Height = -16
      Font.Name = 'Lemon'
      Font.Style = []
      ParentFont = False
      TabOrder = 5
      OnClick = MP8DblClick
      OnDblClick = MP8DblClick
      OnEnter = MP1Enter
      OnExit = MP1Exit
      OnMouseMove = MP1MouseMove
    end
    object MP4: TPanel
      Tag = 4
      Left = 48
      Top = 160
      Width = 353
      Height = 25
      Cursor = crHandPoint
      Caption = 'P'#233'nzt'#225'rak k'#246'z'#246'tti forgalom'
      Font.Charset = ANSI_CHARSET
      Font.Color = clGray
      Font.Height = -16
      Font.Name = 'Lemon'
      Font.Style = []
      ParentFont = False
      TabOrder = 6
      OnClick = MP8DblClick
      OnDblClick = MP8DblClick
      OnEnter = MP1Enter
      OnExit = MP1Exit
      OnMouseMove = MP1MouseMove
    end
    object MP5: TPanel
      Tag = 5
      Left = 48
      Top = 192
      Width = 353
      Height = 25
      Cursor = crHandPoint
      Caption = 'Banki forgalmi adatok'
      Font.Charset = ANSI_CHARSET
      Font.Color = clGray
      Font.Height = -16
      Font.Name = 'Lemon'
      Font.Style = []
      ParentFont = False
      TabOrder = 7
      OnClick = MP8DblClick
      OnDblClick = MP8DblClick
      OnEnter = MP1Enter
      OnExit = MP1Exit
      OnMouseMove = MP1MouseMove
    end
  end
  object kilepo: TTimer
    Enabled = False
    Interval = 100
    OnTimer = kilepoTimer
    Left = 16
    Top = 72
  end
end
