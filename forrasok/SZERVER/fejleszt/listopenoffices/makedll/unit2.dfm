object Form2: TForm2
  Left = 589
  Top = 332
  BorderStyle = bsNone
  ClientHeight = 143
  ClientWidth = 383
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
  object ALAPLAP: TPanel
    Left = 0
    Top = 0
    Width = 380
    Height = 140
    BevelOuter = bvNone
    Color = clWhite
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Calibri'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 0
    object Shape1: TShape
      Left = 0
      Top = 0
      Width = 380
      Height = 140
      Align = alClient
      Pen.Color = clRed
      Pen.Width = 5
    end
    object Label1: TLabel
      Left = 24
      Top = 24
      Width = 328
      Height = 23
      Caption = 'A K'#201'RT ID'#336'SZAK ALATT A NYITVATARTOTT'
    end
    object Label2: TLabel
      Left = 96
      Top = 56
      Width = 188
      Height = 23
      Caption = 'P'#201'NZT'#193'RAK KIGY'#220'JT'#201'SE'
    end
    object CSIK: TProgressBar
      Left = 24
      Top = 96
      Width = 337
      Height = 17
      Min = 0
      Max = 100
      Smooth = True
      TabOrder = 0
    end
  end
  object RECQUERY: TIBQuery
    Database = RECDBASE
    Transaction = RECTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 168
    Top = 32
  end
  object RECDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = RECTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 208
    Top = 32
  end
  object RECTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = RECDBASE
    AutoStopAction = saNone
    Left = 248
    Top = 32
  end
  object GYUJTOQUERY: TIBQuery
    Database = GYUJTODBASE
    Transaction = GYUJTOTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 168
    Top = 72
  end
  object GYUJTODBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\IRODAGYUJTO.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = GYUJTOTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 208
    Top = 72
  end
  object GYUJTOTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = GYUJTODBASE
    AutoStopAction = saNone
    Left = 248
    Top = 72
  end
  object KILEPO: TTimer
    Enabled = False
    Interval = 200
    OnTimer = KILEPOTimer
    Left = 296
    Top = 32
  end
  object NAPLOQUERY: TIBQuery
    Database = NAPLODBASE
    Transaction = NAPLOTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 168
    Top = 104
  end
  object NAPLODBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\DAYBOOK.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = NAPLOTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 208
    Top = 104
  end
  object NAPLOTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = NAPLODBASE
    AutoStopAction = saNone
    Left = 248
    Top = 104
  end
end
