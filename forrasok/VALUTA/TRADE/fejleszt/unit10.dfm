object PAYSAFEFORM: TPAYSAFEFORM
  Left = 192
  Top = 124
  BorderStyle = bsNone
  Caption = 'PAYSAFEFORM'
  ClientHeight = 750
  ClientWidth = 1007
  Color = 84652287
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object Shape1: TShape
    Left = 0
    Top = 0
    Width = 1007
    Height = 750
    Align = alClient
    Brush.Color = 5288191
    Pen.Color = clBlue
    Pen.Width = 8
  end
  object Label1: TLabel
    Left = 96
    Top = 48
    Width = 822
    Height = 72
    Caption = 'PAYSAFECARD BEFIZET'#201'S'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clBlue
    Font.Height = -64
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object Shape2: TShape
    Left = 312
    Top = 272
    Width = 425
    Height = 217
    Brush.Color = 13421772
    Shape = stRoundRect
  end
  object Label2: TLabel
    Left = 400
    Top = 232
    Width = 247
    Height = 34
    Caption = 'V'#225'laszthat'#243' '#246'sszegek'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clBlue
    Font.Height = -29
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    Transparent = True
  end
  object VISSZAGOMB: TBitBtn
    Left = 888
    Top = 712
    Width = 99
    Height = 25
    Cursor = crHandPoint
    Cancel = True
    Caption = 'VISSZA'
    TabOrder = 0
    OnClick = VISSZAGOMBClick
  end
  object FTPANEL1: TPanel
    Tag = 1
    Left = 328
    Top = 296
    Width = 393
    Height = 41
    Cursor = crHandPoint
    Caption = '2.000 Ft'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clBlack
    Font.Height = -32
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 1
    TabStop = True
    OnClick = FTPANEL1Click
    OnDblClick = FTPANEL1Click
    OnEnter = FTPANEL1Enter
    OnExit = FTPANEL1Exit
    OnMouseMove = FTPANEL1MouseMove
  end
  object FTPANEL2: TPanel
    Tag = 2
    Left = 328
    Top = 344
    Width = 393
    Height = 41
    Cursor = crHandPoint
    Caption = '5.000 Ft'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -32
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 2
    TabStop = True
    OnClick = FTPANEL1Click
    OnDblClick = FTPANEL1Click
    OnEnter = FTPANEL1Enter
    OnExit = FTPANEL1Exit
    OnMouseMove = FTPANEL1MouseMove
  end
  object FTPANEL3: TPanel
    Tag = 3
    Left = 328
    Top = 392
    Width = 393
    Height = 41
    Cursor = crHandPoint
    Caption = '10.000 Ft'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -32
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 3
    TabStop = True
    OnClick = FTPANEL1Click
    OnDblClick = FTPANEL1Click
    OnEnter = FTPANEL1Enter
    OnExit = FTPANEL1Exit
    OnMouseMove = FTPANEL1MouseMove
  end
  object FTPANEL4: TPanel
    Tag = 4
    Left = 328
    Top = 440
    Width = 393
    Height = 41
    Cursor = crHandPoint
    Caption = '25.000 Ft'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -32
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 4
    TabStop = True
    OnClick = FTPANEL1Click
    OnDblClick = FTPANEL1Click
    OnEnter = FTPANEL1Enter
    OnExit = FTPANEL1Exit
    OnMouseMove = FTPANEL1MouseMove
  end
  object IGENYPANEL: TPanel
    Left = -550
    Top = 450
    Width = 689
    Height = 81
    BevelOuter = bvNone
    Color = 5288191
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -27
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 5
    Visible = False
    object INFOTEXT: TLabel
      Left = 32
      Top = 8
      Width = 627
      Height = 31
      Caption = 'Az '#252'gyf'#233'l ig'#233'nyel egy 25.000 forintos paysafecard k'#243'dot'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlue
      Font.Height = -27
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object IGENYGOMB: TBitBtn
      Left = 168
      Top = 48
      Width = 169
      Height = 25
      Cursor = crHandPoint
      Caption = 'Ig'#233'nyl'#233's'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 0
      OnClick = IGENYGOMBClick
    end
    object MEGSEMGOMB: TBitBtn
      Left = 352
      Top = 48
      Width = 169
      Height = 25
      Cursor = crHandPoint
      Caption = 'M'#233'gsem'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 1
      OnClick = VISSZAGOMBClick
    end
  end
  object SIKERPANEL: TPanel
    Left = -600
    Top = 510
    Width = 697
    Height = 89
    BevelOuter = bvNone
    Caption = 'SIKERES TRANZAKCI'#211
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clRed
    Font.Height = -48
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 6
    Visible = False
  end
  object TEARDOWNPANEL: TPanel
    Left = -406
    Top = 206
    Width = 793
    Height = 201
    Color = clWhite
    TabOrder = 7
    Visible = False
    object Label3: TLabel
      Left = 160
      Top = 56
      Width = 484
      Height = 36
      Caption = 'T'#233'pje le a vev'#337' p'#233'ld'#225'ny'#225't '#233's adja oda'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -32
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object TEARGOMB: TBitBtn
      Left = 296
      Top = 128
      Width = 209
      Height = 25
      Cursor = crHandPoint
      Caption = 'ODAADTAM'
      Default = True
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 0
      OnClick = TEARGOMBClick
    end
  end
  object SAJATPANEL: TPanel
    Left = 568
    Top = 176
    Width = 793
    Height = 201
    Color = 16759552
    TabOrder = 8
    Visible = False
    object Label4: TLabel
      Left = 104
      Top = 64
      Width = 615
      Height = 28
      Caption = 'A SAJ'#193'T P'#201'LD'#193'NYT AL'#193' KELL IRATNI AZ '#220'GYF'#201'LLEL'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlue
      Font.Height = -24
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object PSOKEGOMB: TBitBtn
      Left = 328
      Top = 136
      Width = 161
      Height = 25
      Cursor = crHandPoint
      Caption = 'RENDBEN'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 0
      OnClick = PSOKEGOMBClick
    end
  end
  object VEGSZALAG: TPanel
    Left = 232
    Top = 624
    Width = 585
    Height = 41
    Caption = 'K'#214'NYVELEM A TRANZAKCI'#211'T '#201'S KIL'#201'PEK'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clBlue
    Font.Height = -24
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 9
    Visible = False
  end
  object varopanel: TPanel
    Left = 185
    Top = 496
    Width = 689
    Height = 126
    BevelOuter = bvNone
    Color = 5288191
    TabOrder = 10
    Visible = False
    object Label5: TLabel
      Left = 248
      Top = 8
      Width = 32
      Height = 13
      Caption = 'Label5'
    end
    object Label6: TLabel
      Left = 160
      Top = 8
      Width = 377
      Height = 26
      Caption = 'V'#193'ROK A VISSZAIGAZOL'#193'SRA'
      Font.Charset = ANSI_CHARSET
      Font.Color = clBlue
      Font.Height = -20
      Font.Name = 'Elephant'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object varomemo: TMemo
      Left = 248
      Top = 40
      Width = 201
      Height = 73
      BorderStyle = bsNone
      Color = 5288191
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlue
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      Lines.Strings = (
        ''
        '')
      ParentFont = False
      TabOrder = 0
    end
  end
end
