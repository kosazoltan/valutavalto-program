object CIMLETEZOFORM: TCIMLETEZOFORM
  Left = 195
  Top = 118
  BorderStyle = bsNone
  Caption = 'A K'#201'SZLETP'#211'TL'#193'S CIMLETEZ'#201'SE ....'
  ClientHeight = 496
  ClientWidth = 742
  Color = clGray
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  WindowState = wsMaximized
  OnActivate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object CIMLETPANEL: TPanel
    Left = 216
    Top = 16
    Width = 513
    Height = 385
    BevelInner = bvRaised
    BevelWidth = 4
    Color = clInactiveCaptionText
    TabOrder = 0
    object Label1: TLabel
      Left = 104
      Top = 16
      Width = 314
      Height = 24
      Caption = 'VALUTAK'#201'SZLETEK P'#211'TL'#193'SA'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clNavy
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label3: TLabel
      Left = 272
      Top = 336
      Width = 100
      Height = 18
      Caption = 'CIMLETEZVE:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clNavy
      Font.Height = -15
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object Label4: TLabel
      Left = 120
      Top = 40
      Width = 59
      Height = 16
      Caption = 'D'#193'TUM:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object LONGDATUMNEV: TLabel
      Left = 184
      Top = 40
      Width = 237
      Height = 17
      Caption = '2007 SZEPTEMBER 23 CS'#220'T'#214'RT'#214'K'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clNavy
      Font.Height = -15
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object CE1: TEdit
      Tag = 1
      Left = 104
      Top = 138
      Width = 49
      Height = 24
      BevelInner = bvLowered
      BevelKind = bkSoft
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      MaxLength = 4
      ParentFont = False
      TabOrder = 0
      Text = '9876'
      OnEnter = CE1Enter
      OnExit = CE14Exit
      OnKeyDown = CE1KeyDown
    end
    object CE2: TEdit
      Tag = 2
      Left = 104
      Top = 166
      Width = 49
      Height = 24
      BevelKind = bkSoft
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      MaxLength = 4
      ParentFont = False
      TabOrder = 1
      OnEnter = CE1Enter
      OnExit = CE14Exit
      OnKeyDown = CE1KeyDown
    end
    object CE3: TEdit
      Tag = 3
      Left = 104
      Top = 192
      Width = 49
      Height = 24
      BevelKind = bkSoft
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      MaxLength = 4
      ParentFont = False
      TabOrder = 2
      OnEnter = CE1Enter
      OnExit = CE14Exit
      OnKeyDown = CE1KeyDown
    end
    object CE4: TEdit
      Tag = 4
      Left = 104
      Top = 216
      Width = 49
      Height = 24
      BevelKind = bkSoft
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      MaxLength = 4
      ParentFont = False
      TabOrder = 3
      OnEnter = CE1Enter
      OnExit = CE14Exit
      OnKeyDown = CE1KeyDown
    end
    object CE5: TEdit
      Tag = 5
      Left = 104
      Top = 242
      Width = 49
      Height = 24
      BevelKind = bkSoft
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      MaxLength = 4
      ParentFont = False
      TabOrder = 4
      OnEnter = CE1Enter
      OnExit = CE14Exit
      OnKeyDown = CE1KeyDown
    end
    object CE6: TEdit
      Tag = 6
      Left = 104
      Top = 268
      Width = 49
      Height = 24
      BevelKind = bkSoft
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      MaxLength = 4
      ParentFont = False
      TabOrder = 5
      OnEnter = CE1Enter
      OnExit = CE14Exit
      OnKeyDown = CE1KeyDown
    end
    object CE7: TEdit
      Tag = 7
      Left = 104
      Top = 294
      Width = 49
      Height = 24
      BevelKind = bkSoft
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      MaxLength = 4
      ParentFont = False
      TabOrder = 6
      OnEnter = CE1Enter
      OnExit = CE14Exit
      OnKeyDown = CE1KeyDown
    end
    object CE8: TEdit
      Tag = 8
      Left = 344
      Top = 138
      Width = 49
      Height = 24
      BevelKind = bkSoft
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      MaxLength = 4
      ParentFont = False
      TabOrder = 7
      OnEnter = CE1Enter
      OnExit = CE14Exit
      OnKeyDown = CE1KeyDown
    end
    object CE9: TEdit
      Tag = 9
      Left = 344
      Top = 164
      Width = 49
      Height = 24
      BevelKind = bkSoft
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      MaxLength = 4
      ParentFont = False
      TabOrder = 8
      OnEnter = CE1Enter
      OnExit = CE14Exit
      OnKeyDown = CE1KeyDown
    end
    object CE10: TEdit
      Tag = 10
      Left = 344
      Top = 190
      Width = 49
      Height = 24
      BevelKind = bkSoft
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      MaxLength = 4
      ParentFont = False
      TabOrder = 9
      OnEnter = CE1Enter
      OnExit = CE14Exit
      OnKeyDown = CE1KeyDown
    end
    object CE11: TEdit
      Tag = 11
      Left = 344
      Top = 216
      Width = 49
      Height = 24
      BevelKind = bkSoft
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      MaxLength = 4
      ParentFont = False
      TabOrder = 10
      OnEnter = CE1Enter
      OnExit = CE14Exit
      OnKeyDown = CE1KeyDown
    end
    object CE12: TEdit
      Tag = 12
      Left = 344
      Top = 242
      Width = 49
      Height = 24
      BevelKind = bkSoft
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      MaxLength = 4
      ParentFont = False
      TabOrder = 11
      OnEnter = CE1Enter
      OnExit = CE14Exit
      OnKeyDown = CE1KeyDown
    end
    object CE13: TEdit
      Tag = 13
      Left = 344
      Top = 268
      Width = 49
      Height = 24
      BevelKind = bkSoft
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      MaxLength = 4
      ParentFont = False
      TabOrder = 12
      OnEnter = CE1Enter
      OnExit = CE14Exit
      OnKeyDown = CE1KeyDown
    end
    object CE14: TEdit
      Tag = 14
      Left = 344
      Top = 294
      Width = 49
      Height = 21
      BevelKind = bkSoft
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      MaxLength = 4
      ParentFont = False
      TabOrder = 13
      OnEnter = CE1Enter
      OnExit = CE14Exit
      OnKeyDown = CE1KeyDown
    end
    object SP1: TPanel
      Left = 160
      Top = 138
      Width = 89
      Height = 23
      BevelInner = bvRaised
      Caption = '123 456 789'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 14
    end
    object SP2: TPanel
      Left = 160
      Top = 164
      Width = 89
      Height = 23
      BevelInner = bvRaised
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 15
    end
    object SP3: TPanel
      Left = 160
      Top = 190
      Width = 89
      Height = 23
      BevelInner = bvRaised
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 16
    end
    object SP4: TPanel
      Left = 160
      Top = 216
      Width = 89
      Height = 23
      BevelInner = bvRaised
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 17
    end
    object SP5: TPanel
      Left = 160
      Top = 242
      Width = 89
      Height = 23
      BevelInner = bvRaised
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 18
    end
    object SP6: TPanel
      Left = 160
      Top = 268
      Width = 89
      Height = 23
      BevelInner = bvRaised
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 19
    end
    object SP7: TPanel
      Left = 160
      Top = 294
      Width = 89
      Height = 23
      BevelInner = bvRaised
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 20
    end
    object SP8: TPanel
      Left = 400
      Top = 138
      Width = 89
      Height = 23
      BevelInner = bvRaised
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -16
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 21
    end
    object SP9: TPanel
      Left = 400
      Top = 164
      Width = 89
      Height = 23
      BevelInner = bvRaised
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -16
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 22
    end
    object SP10: TPanel
      Left = 400
      Top = 190
      Width = 89
      Height = 23
      BevelInner = bvRaised
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -16
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 23
    end
    object SP11: TPanel
      Left = 400
      Top = 216
      Width = 89
      Height = 23
      BevelInner = bvRaised
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -16
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 24
    end
    object SP12: TPanel
      Left = 400
      Top = 242
      Width = 89
      Height = 23
      BevelInner = bvRaised
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -16
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 25
    end
    object SP13: TPanel
      Left = 400
      Top = 268
      Width = 89
      Height = 23
      BevelInner = bvRaised
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -16
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 26
    end
    object SP14: TPanel
      Left = 400
      Top = 294
      Width = 89
      Height = 23
      BevelInner = bvRaised
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -16
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 27
    end
    object CIMLETEZETTPANEL: TPanel
      Left = 384
      Top = 328
      Width = 105
      Height = 33
      Caption = '987 654 345'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 28
    end
    object ROVNEVPANEL: TPanel
      Left = 32
      Top = 72
      Width = 65
      Height = 41
      BevelInner = bvRaised
      BevelWidth = 2
      Caption = 'USD'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clOlive
      Font.Height = -16
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 29
    end
    object TELJESNEVPANEL: TPanel
      Left = 104
      Top = 72
      Width = 201
      Height = 41
      BevelInner = bvRaised
      BevelWidth = 2
      Caption = 'KANADAI DOLL'#193'R'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clOlive
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 30
    end
    object CP1: TPanel
      Left = 24
      Top = 138
      Width = 73
      Height = 23
      BevelInner = bvRaised
      Caption = '20 000'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 31
    end
    object CP2: TPanel
      Left = 24
      Top = 164
      Width = 73
      Height = 23
      BevelInner = bvRaised
      Caption = '10 000'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 32
    end
    object CP3: TPanel
      Left = 24
      Top = 190
      Width = 73
      Height = 23
      BevelInner = bvRaised
      Caption = '5 000'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 33
    end
    object CP4: TPanel
      Left = 24
      Top = 216
      Width = 73
      Height = 23
      BevelInner = bvRaised
      Caption = '2 000'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 34
    end
    object CP5: TPanel
      Tag = 5
      Left = 24
      Top = 242
      Width = 73
      Height = 23
      BevelInner = bvRaised
      Caption = '1 000'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 35
    end
    object CP6: TPanel
      Left = 24
      Top = 268
      Width = 73
      Height = 23
      BevelInner = bvRaised
      Caption = '500'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 36
    end
    object CP7: TPanel
      Left = 24
      Top = 294
      Width = 73
      Height = 23
      BevelInner = bvRaised
      Caption = '200'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 37
    end
    object CP8: TPanel
      Left = 264
      Top = 138
      Width = 73
      Height = 23
      Caption = '100'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 38
    end
    object CP9: TPanel
      Left = 264
      Top = 164
      Width = 73
      Height = 23
      Caption = '50'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 39
    end
    object CP10: TPanel
      Left = 264
      Top = 190
      Width = 73
      Height = 23
      Caption = '20'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 40
    end
    object CP11: TPanel
      Left = 264
      Top = 216
      Width = 73
      Height = 23
      Caption = '10'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 41
    end
    object CP12: TPanel
      Left = 264
      Top = 242
      Width = 73
      Height = 23
      Caption = '5'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 42
    end
    object CP13: TPanel
      Left = 264
      Top = 268
      Width = 73
      Height = 23
      Caption = '2'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 43
    end
    object CP14: TPanel
      Left = 264
      Top = 294
      Width = 73
      Height = 23
      Caption = '1'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 44
    end
    object TAKPANEL1: TPanel
      Tag = 1
      Left = 104
      Top = 138
      Width = 145
      Height = 24
      Color = clInactiveCaptionText
      TabOrder = 45
    end
    object TAKPANEL2: TPanel
      Tag = 2
      Left = 104
      Top = 164
      Width = 145
      Height = 24
      Color = clInactiveCaptionText
      TabOrder = 46
    end
    object TAKPANEL3: TPanel
      Tag = 3
      Left = 104
      Top = 190
      Width = 145
      Height = 24
      Color = clInactiveCaptionText
      TabOrder = 47
    end
    object TAKPANEL4: TPanel
      Tag = 4
      Left = 104
      Top = 216
      Width = 145
      Height = 24
      Color = clInactiveCaptionText
      TabOrder = 48
    end
    object TAKPANEL5: TPanel
      Tag = 5
      Left = 104
      Top = 240
      Width = 145
      Height = 24
      Color = clInactiveCaptionText
      TabOrder = 49
    end
    object TAKPANEL6: TPanel
      Tag = 6
      Left = 104
      Top = 268
      Width = 145
      Height = 24
      Color = clInactiveCaptionText
      TabOrder = 50
    end
    object TAKPANEL7: TPanel
      Tag = 7
      Left = 104
      Top = 294
      Width = 145
      Height = 24
      Color = clInactiveCaptionText
      TabOrder = 51
    end
    object TAKPANEL8: TPanel
      Tag = 8
      Left = 344
      Top = 162
      Width = 145
      Height = 24
      Color = clInactiveCaptionText
      TabOrder = 52
    end
    object TAKPANEL9: TPanel
      Tag = 9
      Left = 344
      Top = 140
      Width = 145
      Height = 24
      Color = clInactiveCaptionText
      TabOrder = 53
    end
    object TAKPANEL10: TPanel
      Tag = 10
      Left = 344
      Top = 190
      Width = 145
      Height = 24
      Color = clInactiveCaptionText
      TabOrder = 54
    end
    object TAKPANEL11: TPanel
      Tag = 11
      Left = 344
      Top = 216
      Width = 145
      Height = 24
      Color = clInactiveCaptionText
      TabOrder = 55
    end
    object TAKPANEL12: TPanel
      Tag = 12
      Left = 344
      Top = 242
      Width = 145
      Height = 24
      Color = clInactiveCaptionText
      TabOrder = 56
    end
    object TAKPANEL13: TPanel
      Tag = 13
      Left = 344
      Top = 268
      Width = 145
      Height = 24
      Color = clInactiveCaptionText
      TabOrder = 57
    end
    object TAKPANEL14: TPanel
      Tag = 14
      Left = 344
      Top = 294
      Width = 145
      Height = 24
      Color = clInactiveCaptionText
      TabOrder = 58
    end
  end
  object Panel19: TPanel
    Left = 8
    Top = 16
    Width = 201
    Height = 473
    BevelInner = bvRaised
    BevelWidth = 3
    Color = clInactiveCaptionText
    TabOrder = 1
    OnMouseMove = Panel19MouseMove
    object Label6: TLabel
      Left = 32
      Top = 32
      Width = 110
      Height = 18
      Caption = 'VALUTANEMEK'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clNavy
      Font.Height = -15
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object VP1: TPanel
      Left = 16
      Top = 56
      Width = 161
      Height = 17
      Cursor = crHandPoint
      Caption = 'AMERIKAI DOLL'#193'R'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      OnClick = VPClick
      OnMouseMove = VPMouseMove
    end
    object VP2: TPanel
      Tag = 1
      Left = 16
      Top = 72
      Width = 161
      Height = 17
      Cursor = crHandPoint
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
      OnClick = VPClick
      OnMouseMove = VPMouseMove
    end
    object VP3: TPanel
      Tag = 2
      Left = 16
      Top = 88
      Width = 161
      Height = 17
      Cursor = crHandPoint
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
      OnClick = VPClick
      OnMouseMove = VPMouseMove
    end
    object VP4: TPanel
      Tag = 3
      Left = 16
      Top = 104
      Width = 161
      Height = 17
      Cursor = crHandPoint
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 3
      OnClick = VPClick
      OnMouseMove = VPMouseMove
    end
    object VP5: TPanel
      Tag = 4
      Left = 16
      Top = 120
      Width = 161
      Height = 17
      Cursor = crHandPoint
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 4
      OnClick = VPClick
      OnMouseMove = VPMouseMove
    end
    object VP6: TPanel
      Tag = 5
      Left = 16
      Top = 136
      Width = 161
      Height = 17
      Cursor = crHandPoint
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 5
      OnClick = VPClick
      OnMouseMove = VPMouseMove
    end
    object VP7: TPanel
      Tag = 6
      Left = 16
      Top = 152
      Width = 161
      Height = 17
      Cursor = crHandPoint
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 6
      OnClick = VPClick
      OnMouseMove = VPMouseMove
    end
    object VP8: TPanel
      Tag = 7
      Left = 16
      Top = 168
      Width = 161
      Height = 17
      Cursor = crHandPoint
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 7
      OnClick = VPClick
      OnMouseMove = VPMouseMove
    end
    object VP9: TPanel
      Tag = 8
      Left = 16
      Top = 184
      Width = 161
      Height = 17
      Cursor = crHandPoint
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 8
      OnClick = VPClick
      OnMouseMove = VPMouseMove
    end
    object VP10: TPanel
      Tag = 9
      Left = 16
      Top = 200
      Width = 161
      Height = 17
      Cursor = crHandPoint
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 9
      OnClick = VPClick
      OnMouseMove = VPMouseMove
    end
    object VP11: TPanel
      Tag = 10
      Left = 16
      Top = 216
      Width = 161
      Height = 17
      Cursor = crHandPoint
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 10
      OnClick = VPClick
      OnMouseMove = VPMouseMove
    end
    object VP12: TPanel
      Tag = 11
      Left = 16
      Top = 232
      Width = 161
      Height = 17
      Cursor = crHandPoint
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 11
      OnClick = VPClick
      OnMouseMove = VPMouseMove
    end
    object VP13: TPanel
      Tag = 12
      Left = 16
      Top = 248
      Width = 161
      Height = 17
      Cursor = crHandPoint
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 12
      OnClick = VPClick
      OnMouseMove = VPMouseMove
    end
    object VP14: TPanel
      Tag = 13
      Left = 16
      Top = 264
      Width = 161
      Height = 17
      Cursor = crHandPoint
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 13
      OnClick = VPClick
      OnMouseMove = VPMouseMove
    end
    object VP15: TPanel
      Tag = 14
      Left = 16
      Top = 280
      Width = 161
      Height = 17
      Cursor = crHandPoint
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 14
      OnClick = VPClick
      OnMouseMove = VPMouseMove
    end
    object VP16: TPanel
      Tag = 15
      Left = 16
      Top = 296
      Width = 161
      Height = 17
      Cursor = crHandPoint
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 15
      OnClick = VPClick
      OnMouseMove = VPMouseMove
    end
    object VP17: TPanel
      Tag = 16
      Left = 16
      Top = 312
      Width = 161
      Height = 17
      Cursor = crHandPoint
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 16
      OnClick = VPClick
      OnMouseMove = VPMouseMove
    end
    object VP18: TPanel
      Tag = 17
      Left = 16
      Top = 328
      Width = 161
      Height = 17
      Cursor = crHandPoint
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 17
      OnClick = VPClick
      OnMouseMove = VPMouseMove
    end
    object VP19: TPanel
      Tag = 18
      Left = 16
      Top = 344
      Width = 161
      Height = 17
      Cursor = crHandPoint
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 18
      OnClick = VPClick
      OnMouseMove = VPMouseMove
    end
    object VP20: TPanel
      Tag = 19
      Left = 16
      Top = 360
      Width = 161
      Height = 17
      Cursor = crHandPoint
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 19
      OnClick = VPClick
      OnMouseMove = VPMouseMove
    end
    object VP21: TPanel
      Tag = 20
      Left = 16
      Top = 376
      Width = 161
      Height = 17
      Cursor = crHandPoint
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 20
      OnClick = VPClick
      OnMouseMove = VPMouseMove
    end
    object VP22: TPanel
      Tag = 21
      Left = 16
      Top = 392
      Width = 161
      Height = 17
      Cursor = crHandPoint
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 21
      OnClick = VPClick
      OnMouseMove = VPMouseMove
    end
    object Vp23: TPanel
      Tag = 22
      Left = 16
      Top = 408
      Width = 161
      Height = 17
      Cursor = crHandPoint
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 22
      OnClick = VPClick
      OnMouseMove = VPMouseMove
    end
    object VP24: TPanel
      Tag = 23
      Left = 16
      Top = 424
      Width = 161
      Height = 17
      Cursor = crHandPoint
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 23
      OnClick = VPClick
      OnMouseMove = VPMouseMove
    end
    object VP25: TPanel
      Tag = 24
      Left = 16
      Top = 440
      Width = 161
      Height = 17
      Cursor = crHandPoint
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 24
      OnClick = VPClick
      OnMouseMove = VPMouseMove
    end
  end
  object Panel45: TPanel
    Left = 216
    Top = 404
    Width = 513
    Height = 85
    BevelInner = bvRaised
    BevelWidth = 3
    Color = clInactiveCaptionText
    TabOrder = 2
    object CIMLETLISTAGOMB: TBitBtn
      Left = 176
      Top = 16
      Width = 153
      Height = 41
      Cursor = crHandPoint
      Caption = 'CIMLETEZ'#201'S MEGN'#201'Z'#201'SE'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
    end
    object EXITGOMB: TBitBtn
      Left = 336
      Top = 16
      Width = 153
      Height = 41
      Cursor = crHandPoint
      Caption = 'R'#214'GZIT'#201'S N'#201'LK'#220'L KIL'#201'P'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      TabStop = False
      OnClick = EXITGOMBClick
    end
    object ROGZITSDGOMB: TBitBtn
      Left = 16
      Top = 16
      Width = 153
      Height = 41
      Cursor = crHandPoint
      Caption = 'AZ ADATOK R'#214'GZIT'#201'SE'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
      OnClick = CimletRogzites
    end
  end
  object CIMTARTABLA: TIBTable
    Database = CIMTARDBASE
    Transaction = CIMTARTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 624
    Top = 32
  end
  object CIMTARDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = CIMTARTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 656
    Top = 32
  end
  object CIMTARTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = CIMTARDBASE
    AutoStopAction = saNone
    Left = 688
    Top = 32
  end
  object ARFOLYAMTABLA: TIBTable
    Database = ARFOLYAMDBASE
    Transaction = ARFOLYAMTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    IndexFieldNames = 'VALUTANEM'
    TableName = 'ARFOLYAM'
    Left = 624
    Top = 72
  end
  object ARFOLYAMDBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = ARFOLYAMTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 656
    Top = 72
  end
  object ARFOLYAMTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = ARFOLYAMDBASE
    AutoStopAction = saNone
    Left = 688
    Top = 72
  end
  object QuerytABLA: TIBQuery
    Database = CIMTARDBASE
    Transaction = CIMTARTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 232
    Top = 32
  end
  object QUERYDBASE: TIBDatabase
    DatabaseName = 'localhost:'
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 264
    Top = 32
  end
  object QUERYTRANZ: TIBTransaction
    Active = False
    AutoStopAction = saNone
    Left = 296
    Top = 32
  end
  object CIMLETTABLA: TIBTable
    Database = CIMLETDBASE
    Transaction = CIMLETTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    TableName = 'CIMLET'
    Left = 624
    Top = 112
  end
  object CIMLETDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = CIMLETTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 656
    Top = 112
  end
  object CIMLETTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = CIMLETDBASE
    AutoStopAction = saNone
    Left = 688
    Top = 112
  end
end
