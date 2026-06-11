object Form1: TForm1
  Left = 192
  Top = 125
  BorderStyle = bsSingle
  Caption = 'Form1'
  ClientHeight = 430
  ClientWidth = 330
  Color = clSkyBlue
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object hobekeropanel: TPanel
    Left = 0
    Top = 0
    Width = 321
    Height = 169
    BevelOuter = bvNone
    Color = clGray
    TabOrder = 0
    Visible = False
    object Shape3: TShape
      Left = 0
      Top = 0
      Width = 321
      Height = 169
      Align = alClient
      Brush.Color = clSkyBlue
      Pen.Color = clRed
      Pen.Width = 3
    end
    object Label1: TLabel
      Left = 16
      Top = 24
      Width = 289
      Height = 24
      Caption = 'ADJA MEG A K'#201'RT H'#211'NAPOT'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clNavy
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Shape1: TShape
      Left = 42
      Top = 58
      Width = 235
      Height = 41
      Pen.Width = 2
      Shape = stRoundRect
    end
    object Shape2: TShape
      Left = 16
      Top = 115
      Width = 280
      Height = 35
      Pen.Width = 2
      Shape = stRoundRect
    end
    object EVCOMBO: TComboBox
      Left = 48
      Top = 64
      Width = 81
      Height = 30
      Cursor = crHandPoint
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = []
      ItemHeight = 22
      ParentFont = False
      TabOrder = 0
      Text = '2022'
      OnChange = EVCOMBOChange
    end
    object HOCOMBO: TComboBox
      Left = 128
      Top = 64
      Width = 145
      Height = 29
      Cursor = crHandPoint
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ItemHeight = 21
      ParentFont = False
      TabOrder = 1
      Text = 'SZEPTEMBER'
      OnChange = EVCOMBOChange
    end
    object HONAPOKEGOMB: TBitBtn
      Left = 24
      Top = 120
      Width = 131
      Height = 25
      Cursor = crHandPoint
      Caption = 'H'#211'NAP RENDBEN'
      TabOrder = 2
      OnClick = HONAPOKEGOMBClick
    end
    object HONAPMEGSEMGOMB: TBitBtn
      Left = 160
      Top = 120
      Width = 129
      Height = 25
      Cursor = crHandPoint
      Caption = 'M'#201'GSEM'
      TabOrder = 3
      OnClick = HONAPMEGSEMGOMBClick
    end
  end
  object MUNKAPANEL: TPanel
    Left = 40
    Top = 8
    Width = 289
    Height = 409
    BevelOuter = bvNone
    Color = clSkyBlue
    TabOrder = 1
    Visible = False
    object KERTHOPANEL: TPanel
      Left = 16
      Top = 16
      Width = 249
      Height = 33
      Caption = '2022  SZEPTEMBER'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Calibri'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 0
    end
    object Memo1: TMemo
      Left = 16
      Top = 64
      Width = 257
      Height = 329
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Calibri'
      Font.Style = [fsItalic]
      Lines.Strings = (
        '')
      ParentFont = False
      TabOrder = 1
    end
  end
  object RECQUERY: TIBQuery
    Database = RECDBASE
    Transaction = RECTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 48
    Top = 56
  end
  object RECDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = RECTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 88
    Top = 56
  end
  object RECTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = RECDBASE
    AutoStopAction = saNone
    Left = 128
    Top = 56
  end
  object VQUERY: TIBQuery
    Database = VDBASE
    Transaction = vTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 192
    Top = 304
  end
  object VTABLA: TIBTable
    Database = VDBASE
    Transaction = vTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 160
    Top = 304
  end
  object VDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\V4.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = vTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 224
    Top = 304
  end
  object vTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VDBASE
    AutoStopAction = saNone
    Left = 256
    Top = 304
  end
end
