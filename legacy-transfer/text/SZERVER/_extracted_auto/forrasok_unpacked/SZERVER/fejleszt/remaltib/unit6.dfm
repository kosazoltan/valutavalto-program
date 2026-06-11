object MEZOTOLTOFORM: TMEZOTOLTOFORM
  Left = 192
  Top = 114
  BorderStyle = bsNone
  BorderWidth = 3
  Caption = 'MEZOTOLTOFORM'
  ClientHeight = 451
  ClientWidth = 449
  Color = clNavy
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 88
    Top = 136
    Width = 279
    Height = 20
    Caption = 'MELYIK MEZ'#336'T T'#214'LTSEM FEL ?'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clNavy
    Font.Height = -16
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    Transparent = True
  end
  object panel1: TPanel
    Left = 5
    Top = 5
    Width = 441
    Height = 441
    Color = clYellow
    TabOrder = 0
    object Label3: TLabel
      Left = 88
      Top = 16
      Width = 277
      Height = 29
      Caption = 'A T'#193'BLA  EGY MEZ'#336'J'#201'T'
      Color = clYellow
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentColor = False
      ParentFont = False
      Transparent = True
    end
    object Label5: TLabel
      Left = 40
      Top = 56
      Width = 375
      Height = 29
      Caption = 'AZONOS ADATOKKAL T'#214'LTI FEL'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      Transparent = True
    end
    object Label2: TLabel
      Left = 120
      Top = 136
      Width = 201
      Height = 16
      Caption = 'MELYIK MEZ'#336'T T'#214'LTSEM FEL ?'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clMaroon
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      Transparent = True
    end
    object TIPINFOLABEL: TLabel
      Left = 48
      Top = 224
      Width = 353
      Height = 20
      Caption = 'A V'#193'LASZTOTT MEZ'#336' EGY SZ'#214'VEGES ADAT'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clRed
      Font.Height = -16
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      Transparent = True
    end
    object ILABEL: TLabel
      Left = 104
      Top = 288
      Width = 224
      Height = 13
      Caption = 'A MEZ'#214' FELT'#214'LT'#201'SE AZ AL'#193'BBI SZ'#193'MMAL'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clMaroon
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      Transparent = True
    end
    object FILLMEZOCOMBO: TComboBox
      Left = 96
      Top = 160
      Width = 241
      Height = 24
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ItemHeight = 16
      ParentFont = False
      TabOrder = 0
      Text = 'FILLMEZOCOMBO'
      OnChange = FILLMEZOCOMBOChange
      OnEnter = FILLMEZOCOMBOEnter
      OnExit = FILLMEZOCOMBOExit
    end
    object FILLEDIT: TEdit
      Left = 144
      Top = 312
      Width = 145
      Height = 24
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
      Text = 'FILLEDIT'
      OnEnter = FILLEDITEnter
      OnExit = FILLEDITExit
      OnKeyDown = FILLEDITKeyDown
    end
    object TOLTESGOMB: TBitBtn
      Left = 16
      Top = 384
      Width = 193
      Height = 25
      Cursor = crHandPoint
      Caption = 'T'#214'LTS'#220'K FEL A REKORDOKAT'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
      OnClick = TOLTESGOMBClick
      OnEnter = TOLTESGOMBEnter
      OnExit = TOLTESGOMBExit
    end
    object MEGSEMGOMB: TBitBtn
      Left = 224
      Top = 384
      Width = 193
      Height = 25
      Cursor = crHandPoint
      Caption = 'M'#368'VELET STORN'#211
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 3
      OnClick = MEGSEMGOMBClick
      OnEnter = TOLTESGOMBEnter
      OnExit = TOLTESGOMBExit
    end
  end
end
