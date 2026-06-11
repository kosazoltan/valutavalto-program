object Form1: TForm1
  Left = 385
  Top = 359
  BorderStyle = bsNone
  Caption = 'Form1'
  ClientHeight = 58
  ClientWidth = 358
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
  object Panel1: TPanel
    Left = 8
    Top = 8
    Width = 345
    Height = 49
    Color = clSilver
    TabOrder = 0
    object Label1: TLabel
      Left = 8
      Top = 16
      Width = 315
      Height = 23
      Caption = 'TRANZAKCI'#211' D'#205'JAK BE'#193'LL'#205'T'#193'SA'
      Font.Charset = ANSI_CHARSET
      Font.Color = clBlack
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
  end
  object TRDBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = TRTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 136
    Top = 32
  end
  object TRTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = TRDBASE
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    AutoStopAction = saNone
    Left = 168
    Top = 32
  end
  object KILEPO: TTimer
    Enabled = False
    OnTimer = KILEPOTimer
    Left = 40
    Top = 24
  end
  object TRQUERY: TIBQuery
    Database = TRDBASE
    Transaction = TRTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 96
    Top = 24
  end
end
