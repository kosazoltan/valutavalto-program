object ADATSZETKULDES: TADATSZETKULDES
  Left = 452
  Top = 258
  AlphaBlend = True
  AlphaBlendValue = 220
  BorderStyle = bsNone
  ClientHeight = 283
  ClientWidth = 435
  Color = clRed
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  OnClick = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 8
    Top = 8
    Width = 417
    Height = 266
    TabOrder = 0
    object Label1: TLabel
      Left = 24
      Top = 16
      Width = 380
      Height = 19
      Caption = 'AZ '#193'RFOLYAMOK SZ'#201'TK'#220'LD'#201'SE AZ IROD'#193'KNAK'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clNavy
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object Label2: TLabel
      Left = 88
      Top = 40
      Width = 210
      Height = 19
      Caption = 'A SZERVEREN KERESZT'#220'L'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clNavy
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object ListBox1: TListBox
      Left = 20
      Top = 72
      Width = 377
      Height = 177
      Color = 11599871
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clGray
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ItemHeight = 19
      ParentFont = False
      TabOrder = 0
    end
    object rendbenpanel: TPanel
      Left = 24
      Top = 96
      Width = 369
      Height = 41
      Caption = 'SIKERES '#193'RFOLYAMTER'#205'T'#201'S'
      Color = clLime
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clTeal
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 1
    end
    object ERRORPANEL: TPanel
      Left = 24
      Top = 144
      Width = 369
      Height = 41
      Caption = 'SIKERTELEN '#193'RFOLYAM TER'#205'T'#201'S'
      Color = clRed
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -15
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 2
    end
  end
  object INDITO: TTimer
    Enabled = False
    Interval = 50
    OnTimer = INDITOTimer
    Left = 64
    Top = 208
  end
end
