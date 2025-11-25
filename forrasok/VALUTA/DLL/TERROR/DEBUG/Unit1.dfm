object Form1: TForm1
  Left = 192
  Top = 114
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
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 32
    Top = 136
    Width = 190
    Height = 29
    Caption = 'KERESETT N'#201'V:'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -23
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
  end
  object BitBtn1: TBitBtn
    Left = 40
    Top = 64
    Width = 185
    Height = 25
    Caption = 'N'#201'VCONTROL'
    TabOrder = 0
    OnClick = BitBtn1Click
  end
  object BitBtn2: TBitBtn
    Left = 48
    Top = 264
    Width = 169
    Height = 25
    Caption = 'KIL'#201'P'#201'S'
    TabOrder = 1
    OnClick = BitBtn2Click
  end
  object Panel1: TPanel
    Left = 128
    Top = 192
    Width = 561
    Height = 41
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Cooper Black'
    Font.Style = []
    ParentFont = False
    TabOrder = 2
  end
  object KERNEVEDIT: TEdit
    Left = 232
    Top = 136
    Width = 449
    Height = 31
    BorderStyle = bsNone
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -24
    Font.Name = 'Calibri'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 3
  end
  object BACKPANEL: TPanel
    Left = 40
    Top = 192
    Width = 81
    Height = 41
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -21
    Font.Name = 'Calibri'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 4
  end
  object TEMPQUERY: TIBQuery
    Database = TEMPDBASE
    Transaction = TEMPTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 256
    Top = 56
  end
  object TEMPDBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = TEMPTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 288
    Top = 56
  end
  object TEMPTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = TEMPDBASE
    AutoStopAction = saNone
    Left = 328
    Top = 56
  end
end
