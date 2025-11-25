object importform: Timportform
  Left = 507
  Top = 154
  Width = 375
  Height = 552
  Caption = 'importform'
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
  object NAPTARPANEL: TPanel
    Left = 0
    Top = 0
    Width = 353
    Height = 209
    TabOrder = 0
    object Shape1: TShape
      Left = 1
      Top = 1
      Width = 351
      Height = 207
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
    object KERTNAPPANEL: TPanel
      Left = 112
      Top = 8
      Width = 121
      Height = 25
      BevelOuter = bvNone
      Caption = '2019.05.31'
      Color = clYellow
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 1
    end
    object ELOHOGOMB: TBitBtn
      Left = 8
      Top = 8
      Width = 97
      Height = 25
      Cursor = crHandPoint
      Caption = 'EL'#214'Z'#336' H'#211'NAP'
      TabOrder = 2
      OnClick = ELOHOGOMBClick
    end
    object KOVHOGOMB: TBitBtn
      Left = 240
      Top = 8
      Width = 97
      Height = 25
      Cursor = crHandPoint
      Caption = 'K'#214'VETKEZ'#336' H'#211
      TabOrder = 3
      OnClick = KOVHOGOMBClick
    end
    object DATUMOKEGOMB: TBitBtn
      Left = 16
      Top = 168
      Width = 153
      Height = 25
      Cursor = crHandPoint
      Caption = 'D'#193'TUM RENDBEN'
      TabOrder = 4
      OnClick = DATUMOKEGOMBClick
    end
    object VISSZAGOMB: TBitBtn
      Left = 184
      Top = 168
      Width = 145
      Height = 25
      Cursor = crHandPoint
      Caption = 'VISSZA A F'#336'MEN'#220'RE'
      TabOrder = 5
      OnClick = VISSZAGOMBClick
    end
  end
  object progresspanel: TPanel
    Left = 0
    Top = 208
    Width = 353
    Height = 297
    TabOrder = 1
    object fopanel: TPanel
      Left = 0
      Top = 0
      Width = 353
      Height = 41
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 0
    end
    object MEMOPANEL: TPanel
      Left = 0
      Top = 40
      Width = 353
      Height = 257
      TabOrder = 1
      object uzenopanel: TPanel
        Left = 8
        Top = 8
        Width = 337
        Height = 33
        Color = clWhite
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clBlack
        Font.Height = -15
        Font.Name = 'Arial'
        Font.Style = [fsItalic]
        ParentFont = False
        TabOrder = 0
      end
      object Panel1: TPanel
        Left = 8
        Top = 48
        Width = 337
        Height = 33
        BevelOuter = bvNone
        TabOrder = 1
        object CSIK: TProgressBar
          Left = 8
          Top = 8
          Width = 321
          Height = 17
          Smooth = True
          TabOrder = 0
        end
      end
      object Memo1: TMemo
        Left = 8
        Top = 88
        Width = 337
        Height = 161
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clBlack
        Font.Height = -15
        Font.Name = 'Arial'
        Font.Style = [fsItalic]
        Lines.Strings = (
          '')
        ParentFont = False
        TabOrder = 2
      end
    end
  end
  object IMPQUERY: TIBQuery
    Database = IMPDBASE
    Transaction = IMPTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 16
    Top = 424
  end
  object IMPDBASE: TIBDatabase
    DatabaseName = 'C:\UCTRL\BIZLATOK.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = IMPTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 56
    Top = 424
  end
  object IMPTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = IMPDBASE
    AutoStopAction = saNone
    Left = 96
    Top = 424
  end
  object VQUERY: TIBQuery
    Database = VDBASE
    Transaction = VTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 216
    Top = 272
  end
  object VDBASE: TIBDatabase
    DatabaseName = '185.43.207.99:c:\receptor\database\v143.fdb'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = VTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 256
    Top = 272
  end
  object VTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VDBASE
    AutoStopAction = saNone
    Left = 296
    Top = 272
  end
  object UFQUERY: TIBQuery
    Database = UFDBASE
    Transaction = UFTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 16
    Top = 280
  end
  object UFDBASE: TIBDatabase
    DatabaseName = '185.43.207.99:C:\RECEPTOR\DATABASE\UGYFEL20.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = UFTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 48
    Top = 280
  end
  object UFTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = UFDBASE
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    AutoStopAction = saNone
    Left = 80
    Top = 280
  end
  object RECQUERY: TIBQuery
    Database = RECDBASE
    Transaction = RECTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 216
    Top = 312
  end
  object RECDBASE: TIBDatabase
    DatabaseName = '185.43.207.99:C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = RECTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 256
    Top = 312
  end
  object RECTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = RECDBASE
    AutoStopAction = saNone
    Left = 296
    Top = 312
  end
  object ARTQUERY: TIBQuery
    Database = ARTDBASE
    Transaction = ARTTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 216
    Top = 352
  end
  object ARTDBASE: TIBDatabase
    DatabaseName = '185.43.207.99:C:\CARTCASH\DATABASE\ARTCASH.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = ARTTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 256
    Top = 352
  end
  object ARTTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = ARTDBASE
    AutoStopAction = saNone
    Left = 296
    Top = 352
  end
  object BIZQUERY: TIBQuery
    Database = BIZDBASE
    Transaction = BIZTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 208
    Top = 424
  end
  object BIZDBASE: TIBDatabase
    DatabaseName = 'C:\UCTRL\BIZLATOK.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = BIZTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 248
    Top = 424
  end
  object BIZTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = BIZDBASE
    AutoStopAction = saNone
    Left = 288
    Top = 424
  end
  object VTABLA: TIBTable
    Database = VDBASE
    Transaction = VTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 184
    Top = 272
  end
end
