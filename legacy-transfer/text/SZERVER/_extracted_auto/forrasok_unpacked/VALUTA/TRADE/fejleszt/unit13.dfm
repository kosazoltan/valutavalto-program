object LOGOLVASAS: TLOGOLVASAS
  Left = 192
  Top = 114
  BorderStyle = bsNone
  Caption = 'LOGOLVASAS'
  ClientHeight = 673
  ClientWidth = 927
  Color = clMoneyGreen
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
    Left = 40
    Top = 24
    Width = 3
    Height = 13
  end
  object Label2: TLabel
    Left = 168
    Top = 8
    Width = 570
    Height = 41
    Caption = 'A FOLYAMAT LOG-OK KIOLVAS'#193'SA'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -35
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object NAPTAR: TCalendar
    Left = 296
    Top = 96
    Width = 320
    Height = 120
    Cursor = crHandPoint
    StartOfWeek = 0
    TabOrder = 0
    OnChange = NAPTARChange
  end
  object DATUMPANEL: TPanel
    Left = 368
    Top = 64
    Width = 177
    Height = 25
    Caption = '2016 szeptember 23'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -15
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 1
  end
  object BitBtn2: TBitBtn
    Left = 296
    Top = 64
    Width = 67
    Height = 25
    Cursor = crHandPoint
    Caption = '<<<'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 2
    OnClick = BitBtn2Click
  end
  object BitBtn3: TBitBtn
    Left = 552
    Top = 64
    Width = 65
    Height = 25
    Cursor = crHandPoint
    Caption = '>>>'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 3
    OnClick = BitBtn3Click
  end
  object BitBtn4: TBitBtn
    Left = 296
    Top = 224
    Width = 153
    Height = 25
    Cursor = crHandPoint
    Caption = 'D'#193'TUM RENDBEN'
    TabOrder = 4
    OnClick = BitBtn4Click
  end
  object BitBtn5: TBitBtn
    Left = 464
    Top = 224
    Width = 153
    Height = 25
    Cursor = crHandPoint
    Caption = 'VISSZA A MEN'#368'RE'
    TabOrder = 5
    OnClick = BitBtn1Click
  end
  object LOGLISTA: TListBox
    Left = 16
    Top = 264
    Width = 865
    Height = 393
    BorderStyle = bsNone
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ItemHeight = 19
    ParentFont = False
    TabOrder = 6
  end
end
