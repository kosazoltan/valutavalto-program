object Form1: TForm1
  Left = 192
  Top = 124
  Width = 870
  Height = 640
  Caption = 'Form1'
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
  object Label1: TLabel
    Left = 224
    Top = 56
    Width = 363
    Height = 43
    Caption = 'CIMLETKONTROL - TEST'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -37
    Font.Name = 'Arial Narrow'
    Font.Style = []
    ParentFont = False
  end
  object Label2: TLabel
    Left = 296
    Top = 384
    Width = 189
    Height = 37
    Caption = 'EREDM'#201'NY:'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -32
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
  end
  object GroupBox1: TGroupBox
    Left = 256
    Top = 104
    Width = 249
    Height = 201
    TabOrder = 10
  end
  object BitBtn1: TBitBtn
    Left = 256
    Top = 328
    Width = 257
    Height = 25
    Cursor = crHandPoint
    Caption = 'KONTROL START'
    TabOrder = 0
    OnClick = BitBtn1Click
  end
  object BitBtn2: TBitBtn
    Left = 32
    Top = 560
    Width = 75
    Height = 25
    Caption = 'BitBtn2'
    TabOrder = 1
    OnClick = BitBtn2Click
  end
  object Panel1: TPanel
    Left = 296
    Top = 432
    Width = 193
    Height = 41
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clRed
    Font.Height = -27
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 2
  end
  object R1: TRadioButton
    Tag = 1
    Left = 296
    Top = 120
    Width = 113
    Height = 17
    Caption = 'ESTI Z'#193'R'#193'S'
    Checked = True
    TabOrder = 3
    TabStop = True
  end
  object R2: TRadioButton
    Tag = 2
    Left = 296
    Top = 144
    Width = 113
    Height = 17
    Caption = 'KEZEL'#201'SI D'#205'J'
    TabOrder = 4
  end
  object R3: TRadioButton
    Tag = 3
    Left = 296
    Top = 168
    Width = 113
    Height = 17
    Caption = 'WESTERN UNION'
    TabOrder = 5
  end
  object R4: TRadioButton
    Tag = 4
    Left = 296
    Top = 192
    Width = 233
    Height = 17
    Caption = #193'FA VISSZAIG'#201'NYL'#201'S'
    TabOrder = 6
  end
  object R5: TRadioButton
    Tag = 5
    Left = 296
    Top = 216
    Width = 113
    Height = 17
    Caption = 'FOGLAL'#211' K'#201'SZLETEK'
    TabOrder = 7
  end
  object R6: TRadioButton
    Tag = 6
    Left = 296
    Top = 240
    Width = 265
    Height = 17
    Caption = 'ELEKTROMOS KERESKED'#201'S'
    TabOrder = 8
  end
  object R7: TRadioButton
    Tag = 8
    Left = 296
    Top = 272
    Width = 113
    Height = 17
    Caption = 'AXA BIZTOSIT'#193'S'
    TabOrder = 9
  end
  object HQUERY: TIBQuery
    Database = HDBASE
    Transaction = HTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 8
    Top = 8
  end
  object HDBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = HTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 48
    Top = 8
  end
  object HTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = HDBASE
    AutoStopAction = saNone
    Left = 88
    Top = 8
  end
end
