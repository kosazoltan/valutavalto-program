object Form1: TForm1
  Left = 231
  Top = 369
  Width = 870
  Height = 180
  Caption = 'FDB FILE-OK T'#214'M'#214'RIT'#201'SE '#201'S VISSZABONT'#193'SA'
  Color = clBackground
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object TOMORITOGOMB: TBitBtn
    Left = 16
    Top = 24
    Width = 169
    Height = 25
    Cursor = crHandPoint
    Caption = 'T'#214'M'#214'RIT'#201'S INDUL'
    TabOrder = 0
    OnClick = TOMORITOGOMBClick
  end
  object KILEPOGOMB: TBitBtn
    Left = 16
    Top = 88
    Width = 169
    Height = 25
    Cursor = crHandPoint
    Caption = 'KILEP A PROGRAMB'#211'L'
    TabOrder = 1
    OnClick = KILEPOGOMBClick
  end
  object KIBONTOGOMB: TBitBtn
    Left = 16
    Top = 56
    Width = 169
    Height = 25
    Cursor = crHandPoint
    Caption = 'VISSZABONT'#193'S INDUL'
    TabOrder = 2
    OnClick = KIBONTOGOMBClick
  end
  object Panel1: TPanel
    Left = 200
    Top = 24
    Width = 633
    Height = 25
    TabOrder = 3
  end
  object Panel2: TPanel
    Left = 200
    Top = 56
    Width = 633
    Height = 25
    TabOrder = 4
  end
  object CSIK: TProgressBar
    Left = 200
    Top = 96
    Width = 633
    Height = 17
    Min = 0
    Max = 100
    TabOrder = 5
  end
  object TAKARO: TPanel
    Left = 16
    Top = 24
    Width = 817
    Height = 89
    Color = clYellow
    TabOrder = 6
    object Label1: TLabel
      Left = 104
      Top = 16
      Width = 591
      Height = 18
      Caption = 
        'A T'#214'M'#214'RITEND'#336' FDB-K A c:\receptor\mail\1 K'#214'NYVT'#193'RBAN KELL LENNI'#220 +
        'K'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object ottvangomb: TBitBtn
      Left = 48
      Top = 48
      Width = 225
      Height = 25
      Cursor = crHandPoint
      Caption = 'OTT VANNAK'
      Enabled = False
      TabOrder = 0
      OnClick = ottvangombClick
    end
    object NINCSOTTGOMB: TBitBtn
      Left = 296
      Top = 48
      Width = 225
      Height = 25
      Cursor = crHandPoint
      Caption = 'M'#201'G NINCSENEK '#193'TM'#193'SOLVA'
      Enabled = False
      TabOrder = 1
      OnClick = NINCSOTTGOMBClick
    end
    object BitBtn1: TBitBtn
      Left = 552
      Top = 48
      Width = 225
      Height = 25
      Cursor = crHandPoint
      Caption = 'KIL'#201'P'#201'S'
      TabOrder = 2
      OnClick = BitBtn1Click
    end
  end
  object KILEPO: TTimer
    Enabled = False
    Interval = 150
    OnTimer = KILEPOTimer
    Left = 248
    Top = 8
  end
end
