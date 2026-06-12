object MNBLISTAK: TMNBLISTAK
  Left = 192
  Top = 114
  BorderStyle = bsNone
  Caption = 'MNB LIST'#193'K'
  ClientHeight = 530
  ClientWidth = 749
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
  object Shape1: TShape
    Left = 0
    Top = 0
    Width = 750
    Height = 530
    Brush.Color = 8421631
    Pen.Color = clRed
    Pen.Width = 8
  end
  object Label2: TLabel
    Left = 88
    Top = 8
    Width = 578
    Height = 108
    Caption = 'MNB LIST'#193'K'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clMaroon
    Font.Height = -96
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object mnbstarttimer: TTimer
    Enabled = False
    Interval = 100
    OnTimer = mnbstarttimerTimer
    Left = 72
    Top = 48
  end
  object mnbquery: TIBQuery
    Database = mnbdbase
    Transaction = mnbtranz
    BufferChunks = 1000
    CachedUpdates = False
    Left = 64
    Top = 208
  end
  object mnbdbase: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = mnbtranz
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 104
    Top = 208
  end
  object mnbtranz: TIBTransaction
    Active = False
    DefaultDatabase = mnbdbase
    AutoStopAction = saNone
    Left = 144
    Top = 208
  end
end
