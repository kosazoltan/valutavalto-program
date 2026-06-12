object IMPORTFORM: TIMPORTFORM
  Left = 662
  Top = 153
  BorderStyle = bsNone
  Caption = 'IMPORTFORM'
  ClientHeight = 518
  ClientWidth = 356
  Color = clActiveBorder
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object NAPTARPANEL: TPanel
    Left = 0
    Top = 0
    Width = 353
    Height = 209
    BevelOuter = bvNone
    Color = clSilver
    TabOrder = 0
    object Shape1: TShape
      Left = 0
      Top = 0
      Width = 353
      Height = 209
      Align = alClient
      Pen.Color = clRed
      Pen.Width = 3
    end
    object NAPTAR: TCalendar
      Left = 8
      Top = 40
      Width = 329
      Height = 120
      StartOfWeek = 0
      TabOrder = 0
      OnChange = NAPTARChange
    end
    object ELOHOGOMB: TBitBtn
      Left = 8
      Top = 8
      Width = 97
      Height = 25
      Cursor = crHandPoint
      Caption = 'EL'#214'Z'#336' H'#211'NAP'
      TabOrder = 1
      OnClick = ELOHOGOMBClick
    end
    object KOVHOGOMB: TBitBtn
      Left = 240
      Top = 8
      Width = 97
      Height = 25
      Cursor = crHandPoint
      Caption = 'K'#214'V. H'#211'NAP'
      TabOrder = 2
      OnClick = KOVHOGOMBClick
    end
    object KERTNAPPANEL: TPanel
      Left = 112
      Top = 8
      Width = 121
      Height = 25
      BevelOuter = bvNone
      Caption = '2022.01.01'
      Color = clYellow
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 3
    end
    object DATUMOKEGOMB: TBitBtn
      Left = 16
      Top = 176
      Width = 153
      Height = 25
      Cursor = crHandPoint
      Caption = 'D'#193'TUM RENDBEN'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 4
      OnClick = DATUMOKEGOMBClick
    end
    object VISSZAGOMB: TBitBtn
      Left = 184
      Top = 176
      Width = 145
      Height = 25
      Cursor = crHandPoint
      Caption = 'VISSZA A F'#336'MEN'#368'RE'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 5
      OnClick = Button1Click
    end
  end
  object PROGRESSDPANEL: TPanel
    Left = 8
    Top = 217
    Width = 345
    Height = 296
    BevelOuter = bvNone
    TabOrder = 1
    object FOPANEL: TPanel
      Left = -8
      Top = 0
      Width = 345
      Height = 33
      BevelOuter = bvNone
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Arial'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 0
    end
    object UZENOPANEL: TPanel
      Left = 0
      Top = 48
      Width = 337
      Height = 33
      BevelOuter = bvNone
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 1
    end
    object Panel2: TPanel
      Left = 8
      Top = 88
      Width = 337
      Height = 33
      BevelOuter = bvNone
      Caption = ' '
      TabOrder = 2
      object CSIK: TProgressBar
        Left = 8
        Top = 8
        Width = 321
        Height = 17
        Min = 0
        Max = 100
        Smooth = True
        TabOrder = 0
      end
    end
    object Memo1: TMemo
      Left = 8
      Top = 128
      Width = 329
      Height = 161
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      Lines.Strings = (
        '')
      ParentFont = False
      TabOrder = 3
    end
  end
  object REMOTEQUERY: TIBQuery
    Database = REMOTEDBASE
    Transaction = REMOTETRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 24
    Top = 344
  end
  object REMOTEDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = REMOTETRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 64
    Top = 344
  end
  object REMOTETRANZ: TIBTransaction
    Active = False
    DefaultDatabase = REMOTEDBASE
    AutoStopAction = saNone
    Left = 104
    Top = 344
  end
  object IMPQUERY: TIBQuery
    Database = IMPDBASE
    Transaction = IMPTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 160
    Top = 264
  end
  object IMPDBASE: TIBDatabase
    Connected = True
    DatabaseName = 'C:\UCTRL\DATABASE\BIZLATOK.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = IMPTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 200
    Top = 264
  end
  object IMPTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = IMPDBASE
    AutoStopAction = saNone
    Left = 232
    Top = 264
  end
  object BIZQUERY: TIBQuery
    Database = BIZDBASE
    Transaction = BIZTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 32
    Top = 272
  end
  object BIZDBASE: TIBDatabase
    DatabaseName = 'C:\UCTRL\DATABASE\BIZLATOK.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = BIZTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 64
    Top = 272
  end
  object BIZTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = BIZDBASE
    AutoStopAction = saNone
    Left = 104
    Top = 272
  end
  object IMPTABLA: TIBTable
    Database = IMPDBASE
    Transaction = IMPTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    TableName = 'IMPORT'
    Left = 264
    Top = 264
  end
  object REMOTETABLA: TIBTable
    Database = REMOTEDBASE
    Transaction = REMOTETRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 144
    Top = 344
  end
  object UGYFELQUERY: TIBQuery
    Database = UGYFELDBASE
    Transaction = UGYFELTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 24
    Top = 224
  end
  object IBDatabase1: TIBDatabase
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 168
    Top = 264
  end
  object UGYFELDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = UGYFELTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 56
    Top = 224
  end
  object UGYFELTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = UGYFELDBASE
    AutoStopAction = saNone
    Left = 96
    Top = 224
  end
end
