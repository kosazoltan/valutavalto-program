object ADATBETOLTES: TADATBETOLTES
  Left = 222
  Top = 159
  AlphaBlend = True
  AlphaBlendValue = 200
  BorderStyle = bsNone
  Caption = 'ADATBETOLTES'
  ClientHeight = 426
  ClientWidth = 531
  Color = clSkyBlue
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
    Width = 361
    Height = 425
    Brush.Color = clSkyBlue
    Pen.Width = 5
  end
  object ListBox1: TListBox
    Left = 16
    Top = 144
    Width = 329
    Height = 217
    Cursor = crHandPoint
    BorderStyle = bsNone
    Color = clSkyBlue
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clGray
    Font.Height = -13
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ItemHeight = 16
    ParentFont = False
    TabOrder = 0
  end
  object SIKERESPANEL: TPanel
    Left = 16
    Top = 368
    Width = 329
    Height = 41
    BevelOuter = bvNone
    Caption = 'SIKERES ADATLET'#214'LT'#201'S'
    Color = clSkyBlue
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clRed
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 3
  end
  object alappanel: TPanel
    Left = 8
    Top = 8
    Width = 345
    Height = 121
    BevelOuter = bvNone
    Caption = 'ADATOK LET'#214'LT'#201'SE'
    Color = clSkyBlue
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -21
    Font.Name = 'Arial Narrow'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 4
    object Label4: TLabel
      Left = 64
      Top = 40
      Width = 5
      Height = 25
      BiDiMode = bdRightToLeft
      ParentBiDiMode = False
    end
  end
  object KERDOPANEL: TPanel
    Left = 152
    Top = 8
    Width = 345
    Height = 121
    BevelOuter = bvNone
    Color = clSkyBlue
    TabOrder = 2
    object Label1: TLabel
      Left = 16
      Top = 24
      Width = 321
      Height = 19
      Caption = 'A SAJ'#193'T G'#201'PRE MENTETT '#193'RFOLYAMOT'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      Transparent = True
    end
    object Label2: TLabel
      Left = 120
      Top = 48
      Width = 115
      Height = 19
      Caption = 'T'#214'LTSEM LE ?'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      Transparent = True
    end
    object negomb: TBitBtn
      Left = 64
      Top = 80
      Width = 105
      Height = 25
      Cursor = crHandPoint
      Caption = 'NE'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 0
      OnClick = negombClick
    end
    object igengomb: TBitBtn
      Left = 184
      Top = 80
      Width = 97
      Height = 25
      Cursor = crHandPoint
      Caption = 'IGEN'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 1
      OnClick = igengombClick
    end
  end
  object biztospanel: TPanel
    Left = 240
    Top = 184
    Width = 345
    Height = 105
    BevelOuter = bvNone
    Color = 11599871
    TabOrder = 1
    object Label3: TLabel
      Left = 96
      Top = 16
      Width = 148
      Height = 28
      Caption = 'BIZTOSAN ??'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clRed
      Font.Height = -24
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object BIZTOSANGOMB: TBitBtn
      Left = 48
      Top = 56
      Width = 105
      Height = 25
      Cursor = crHandPoint
      Caption = 'BIZTOSAN'
      TabOrder = 0
      OnClick = BIZTOSANGOMBClick
    end
    object MEGSEMGOMB: TBitBtn
      Left = 168
      Top = 56
      Width = 97
      Height = 25
      Cursor = crHandPoint
      Caption = 'M'#201'GSEM'
      TabOrder = 1
      OnClick = MEGSEMGOMBClick
    end
  end
  object INDITO: TTimer
    Enabled = False
    Interval = 50
    OnTimer = INDITOTimer
    Left = 288
    Top = 16
  end
  object TIMEOUTTIMER: TTimer
    Enabled = False
    Interval = 30000
    OnTimer = TIMEOUTTIMERTimer
    Left = 16
    Top = 16
  end
  object KILEPOTIMER: TTimer
    Enabled = False
    Interval = 1500
    OnTimer = KILEPOTIMERTimer
    Left = 320
    Top = 16
  end
end
