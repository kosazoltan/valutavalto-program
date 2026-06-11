object Form2: TForm2
  Left = 192
  Top = 125
  Width = 370
  Height = 614
  Caption = 'JOGI SZEM'#201'LYEK LEV'#193'LOGAT'#193'SA'
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
    Left = 0
    Top = 0
    Width = 350
    Height = 289
    BevelOuter = bvNone
    Color = clMoneyGreen
    TabOrder = 0
    object Label1: TLabel
      Left = 56
      Top = 16
      Width = 243
      Height = 24
      Caption = 'V'#193'LASSZ EGY NAPOT'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Cooper Black'
      Font.Style = []
      ParentFont = False
    end
    object HONAPOKEGOMB: TBitBtn
      Left = 46
      Top = 256
      Width = 121
      Height = 25
      Cursor = crHandPoint
      Caption = 'D'#193'TUM RENDBEN'
      TabOrder = 0
      OnClick = HONAPOKEGOMBClick
    end
    object BitBtn2: TBitBtn
      Left = 178
      Top = 256
      Width = 121
      Height = 25
      Cursor = crHandPoint
      Caption = 'M'#201'GSEM'
      TabOrder = 1
      OnClick = BitBtn2Click
    end
    object NAPTAR: TCalendar
      Left = 16
      Top = 88
      Width = 320
      Height = 120
      StartOfWeek = 0
      TabOrder = 2
      OnChange = NAPTARDblClick
      OnDblClick = NAPTARDblClick
      OnKeyUp = NAPTARKeyUp
    end
    object BitBtn1: TBitBtn
      Left = 16
      Top = 56
      Width = 153
      Height = 25
      Caption = '<<<   EL'#214'Z'#336' H'#211'NAP'
      TabOrder = 3
      OnClick = BitBtn1Click
    end
    object BitBtn3: TBitBtn
      Left = 176
      Top = 56
      Width = 155
      Height = 25
      Caption = 'K'#214'VETKEZ'#336' H'#211'NAP >>>'
      TabOrder = 4
      OnClick = BitBtn3Click
    end
    object DATUMPANEL: TPanel
      Left = 16
      Top = 216
      Width = 321
      Height = 33
      BevelOuter = bvNone
      Caption = '2022 SZEPTEMBER 30'
      Color = clMoneyGreen
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clTeal
      Font.Height = -24
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 5
    end
  end
  object Panel3: TPanel
    Left = 0
    Top = 296
    Width = 350
    Height = 265
    BevelOuter = bvNone
    Color = clMoneyGreen
    TabOrder = 1
    object Memo1: TMemo
      Left = 16
      Top = 16
      Width = 321
      Height = 233
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 0
    end
  end
  object FUGGONY: TPanel
    Left = 15
    Top = 0
    Width = 322
    Height = 570
    BevelOuter = bvNone
    Color = clMoneyGreen
    TabOrder = 2
    Visible = False
    object Label2: TLabel
      Left = 64
      Top = 120
      Width = 190
      Height = 21
      Caption = 'AZ EXCELT'#193'BL'#193'T '
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Cooper Black'
      Font.Style = []
      ParentFont = False
    end
    object Label3: TLabel
      Left = 80
      Top = 144
      Width = 148
      Height = 21
      Caption = 'R'#214'GZITETTEM'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Cooper Black'
      Font.Style = []
      ParentFont = False
    end
    object Label4: TLabel
      Left = 32
      Top = 192
      Width = 258
      Height = 33
      Caption = 'C:\JOGISZEMELY\EXCEL'
      Font.Charset = ANSI_CHARSET
      Font.Color = clRed
      Font.Height = -27
      Font.Name = 'Calibri'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object Label5: TLabel
      Left = 104
      Top = 232
      Width = 115
      Height = 23
      Caption = 'K'#214'NYVT'#193'RBAN'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Calibri'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object FUGGONYEXCEL: TLabel
      Left = 128
      Top = 312
      Width = 53
      Height = 23
      Caption = 'N'#201'VEN'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Calibri'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object KILEPOGOMB: TBitBtn
      Left = 88
      Top = 472
      Width = 145
      Height = 25
      Cursor = crHandPoint
      Cancel = True
      Caption = 'KIL'#201'P'#201'S'
      Default = True
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 0
      OnClick = KILEPOGOMBClick
    end
    object XLSNEVPANEL: TPanel
      Left = 0
      Top = 264
      Width = 321
      Height = 41
      BevelOuter = bvNone
      Caption = 'JG220405.XLSX'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clRed
      Font.Height = -24
      Font.Name = 'Calibri'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 1
    end
  end
  object VQUERY: TIBQuery
    Database = VDBASE
    Transaction = VTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 176
    Top = 336
  end
  object VDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = VTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 280
    Top = 336
  end
  object VTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VDBASE
    AutoStopAction = saNone
    Left = 208
    Top = 336
  end
  object RECQUERY: TIBQuery
    Database = RECDBASE
    Transaction = RECTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 48
    Top = 296
  end
  object RECDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = RECTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 56
    Top = 344
  end
  object RECTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = RECDBASE
    AutoStopAction = saNone
    Left = 88
    Top = 344
  end
  object ARCQUERY: TIBQuery
    Database = ARCDBASE
    Transaction = ARCTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 48
    Top = 424
  end
  object ARCDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = ARCTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 56
    Top = 392
  end
  object ARCTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = ARCDBASE
    AutoStopAction = saNone
    Left = 88
    Top = 392
  end
  object GYUJTOQUERY: TIBQuery
    Database = GYUJTODBASE
    Transaction = GYUJTOTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 136
    Top = 416
  end
  object GYUJTODBASE: TIBDatabase
    DatabaseName = 'C:\JOGISZEMELY\DATABASE\JOGIGYUJTO.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = GYUJTOTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 168
    Top = 416
  end
  object GYUJTOTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = GYUJTODBASE
    AutoStopAction = saNone
    Left = 200
    Top = 416
  end
  object JOGIQUERY: TIBQuery
    Database = JOGIDBASE
    Transaction = JOGITRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 136
    Top = 384
  end
  object JOGIDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = JOGITRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 168
    Top = 384
  end
  object JOGITRANZ: TIBTransaction
    Active = False
    DefaultDatabase = JOGIDBASE
    AutoStopAction = saNone
    Left = 200
    Top = 384
  end
  object VTABLA: TIBTable
    Database = VDBASE
    Transaction = VTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 240
    Top = 336
  end
  object TULAJQUERY: TIBQuery
    Database = TULAJDBASE
    Transaction = TULAJTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 128
    Top = 504
  end
  object TULAJDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = TULAJTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 160
    Top = 504
  end
  object TULAJTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = TULAJDBASE
    AutoStopAction = saNone
    Left = 200
    Top = 504
  end
  object TULAJTABLA: TIBTable
    Database = TULAJDBASE
    Transaction = TULAJTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 96
    Top = 504
  end
  object BFEJQUERY: TIBQuery
    Database = BFEJDBASE
    Transaction = BFEJTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 24
    Top = 40
  end
  object BFEJDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = BFEJTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 64
    Top = 40
  end
  object BFEJTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = BFEJDBASE
    AutoStopAction = saNone
    Left = 96
    Top = 40
  end
end
