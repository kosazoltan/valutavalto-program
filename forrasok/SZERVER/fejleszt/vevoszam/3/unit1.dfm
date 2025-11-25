object Form1: TForm1
  Left = 192
  Top = 125
  Width = 1305
  Height = 675
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
  object Shape1: TShape
    Left = 96
    Top = 160
    Width = 401
    Height = 177
  end
  object Label1: TLabel
    Left = 208
    Top = 352
    Width = 176
    Height = 21
    Caption = 'HAT'#193'ROZATLAN'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Cooper Black'
    Font.Style = []
    ParentFont = False
  end
  object Button1: TButton
    Left = 56
    Top = 32
    Width = 75
    Height = 25
    Caption = 'Button1'
    TabOrder = 0
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 56
    Top = 72
    Width = 75
    Height = 25
    Caption = 'Button2'
    TabOrder = 1
    OnClick = Button2Click
  end
  object Panel1: TPanel
    Left = 104
    Top = 168
    Width = 185
    Height = 41
    Caption = 'BELF'#214'LDI'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Cooper Black'
    Font.Style = []
    ParentFont = False
    TabOrder = 2
  end
  object Panel2: TPanel
    Left = 304
    Top = 168
    Width = 185
    Height = 41
    Caption = 'K'#220'LF'#214'LDI'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Cooper Black'
    Font.Style = []
    ParentFont = False
    TabOrder = 3
  end
  object Panel3: TPanel
    Left = 104
    Top = 216
    Width = 89
    Height = 41
    Caption = 'NATUR'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Calibri'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 4
  end
  object Panel4: TPanel
    Left = 200
    Top = 216
    Width = 89
    Height = 41
    Caption = 'JOGI'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Calibri'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 5
  end
  object Panel5: TPanel
    Left = 304
    Top = 216
    Width = 89
    Height = 41
    Caption = 'NATUR'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Calibri'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 6
  end
  object Panel6: TPanel
    Left = 400
    Top = 216
    Width = 89
    Height = 41
    Caption = 'JOGI'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Calibri'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 7
  end
  object BNPANEL: TPanel
    Left = 104
    Top = 264
    Width = 89
    Height = 41
    Caption = '0'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -21
    Font.Name = 'Calibri'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 8
  end
  object BJPANEL: TPanel
    Left = 200
    Top = 264
    Width = 89
    Height = 41
    Caption = '0'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -21
    Font.Name = 'Calibri'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 9
  end
  object KNPANEL: TPanel
    Left = 304
    Top = 264
    Width = 89
    Height = 41
    Caption = '0'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -21
    Font.Name = 'Calibri'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 10
  end
  object KJPANEL: TPanel
    Left = 400
    Top = 264
    Width = 89
    Height = 41
    Caption = '0'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -21
    Font.Name = 'Calibri'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 11
  end
  object CSIK: TProgressBar
    Left = 104
    Top = 312
    Width = 385
    Height = 17
    Min = 0
    Max = 150
    Smooth = True
    TabOrder = 12
  end
  object hpanel: TPanel
    Left = 208
    Top = 376
    Width = 185
    Height = 41
    Caption = '0'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -21
    Font.Name = 'Calibri'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 13
  end
  object ptpanel: TPanel
    Left = 96
    Top = 112
    Width = 401
    Height = 41
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -21
    Font.Name = 'Calibri'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 14
  end
  object UQUERY: TIBQuery
    Database = UDBASE
    Transaction = UTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 248
    Top = 40
  end
  object UDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\V9.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = UTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 288
    Top = 40
  end
  object UTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = UDBASE
    AutoStopAction = saNone
    Left = 336
    Top = 40
  end
  object UTABLA: TIBTable
    Database = UDBASE
    Transaction = UTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 216
    Top = 40
  end
  object PQUERY: TIBQuery
    Database = PDBASE
    Transaction = PTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 424
    Top = 40
  end
  object PDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\UGYFEL22.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = PTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 464
    Top = 40
  end
  object PTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = PDBASE
    AutoStopAction = saNone
    Left = 504
    Top = 40
  end
end
