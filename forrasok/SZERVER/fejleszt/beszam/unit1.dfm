object Form1: TForm1
  Left = 192
  Top = 114
  BorderStyle = bsNone
  Caption = 'Form1'
  ClientHeight = 606
  ClientWidth = 862
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
  object Shape2: TShape
    Left = 0
    Top = 0
    Width = 862
    Height = 606
    Align = alClient
    Brush.Color = 4539717
    Pen.Color = clWhite
    Pen.Width = 5
  end
  object Shape3: TShape
    Left = 712
    Top = 536
    Width = 129
    Height = 33
    Brush.Color = clSilver
    Shape = stEllipse
  end
  object Label1: TLabel
    Left = 728
    Top = 544
    Width = 93
    Height = 18
    Caption = 'dek@nySoft'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object Panel1: TPanel
    Left = 176
    Top = 80
    Width = 513
    Height = 513
    BevelOuter = bvNone
    Color = 4539717
    TabOrder = 0
    object Shape1: TShape
      Left = 8
      Top = 0
      Width = 500
      Height = 500
      Shape = stEllipse
      OnMouseMove = Shape1MouseMove
    end
    object P12: TPanel
      Tag = 12
      Left = 228
      Top = 24
      Width = 60
      Height = 41
      Cursor = crHandPoint
      BevelOuter = bvNone
      Caption = '12'
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -48
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 0
      OnMouseDown = P11MouseDown
      OnMouseMove = P12MouseMove
    end
    object P6: TPanel
      Tag = 6
      Left = 228
      Top = 449
      Width = 60
      Height = 41
      Cursor = crHandPoint
      BevelOuter = bvNone
      Caption = '6'
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -48
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 1
      OnMouseDown = P11MouseDown
      OnMouseMove = P12MouseMove
    end
    object P9: TPanel
      Tag = 9
      Left = 16
      Top = 236
      Width = 60
      Height = 41
      Cursor = crHandPoint
      BevelOuter = bvNone
      Caption = '9'
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -48
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 2
      OnMouseDown = P11MouseDown
      OnMouseMove = P12MouseMove
    end
    object P3: TPanel
      Tag = 3
      Left = 440
      Top = 236
      Width = 60
      Height = 41
      Cursor = crHandPoint
      Hint = '490'
      BevelOuter = bvNone
      Caption = '3'
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -48
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 3
      OnMouseDown = P11MouseDown
      OnMouseMove = P12MouseMove
    end
    object P1: TPanel
      Tag = 1
      Left = 340
      Top = 63
      Width = 60
      Height = 41
      Cursor = crHandPoint
      BevelOuter = bvNone
      Caption = '1'
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -48
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 4
      OnMouseDown = P11MouseDown
      OnMouseMove = P12MouseMove
    end
    object P2: TPanel
      Tag = 2
      Left = 410
      Top = 142
      Width = 60
      Height = 41
      Cursor = crHandPoint
      BevelOuter = bvNone
      Caption = '2'
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -48
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 5
      OnMouseDown = P11MouseDown
      OnMouseMove = P12MouseMove
    end
    object P10: TPanel
      Tag = 10
      Left = 48
      Top = 142
      Width = 60
      Height = 41
      Cursor = crHandPoint
      BevelOuter = bvNone
      Caption = '10'
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -48
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 6
      OnMouseDown = P11MouseDown
      OnMouseMove = P12MouseMove
    end
    object P11: TPanel
      Tag = 11
      Left = 115
      Top = 63
      Width = 60
      Height = 41
      Cursor = crHandPoint
      BevelOuter = bvNone
      Caption = '11'
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -48
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 7
      OnMouseDown = P11MouseDown
      OnMouseMove = P12MouseMove
    end
    object P8: TPanel
      Tag = 8
      Left = 48
      Top = 323
      Width = 60
      Height = 41
      Cursor = crHandPoint
      BevelOuter = bvNone
      Caption = '8'
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -48
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 8
      OnMouseDown = P11MouseDown
      OnMouseMove = P12MouseMove
    end
    object P7: TPanel
      Tag = 7
      Left = 115
      Top = 410
      Width = 60
      Height = 41
      Cursor = crHandPoint
      BevelOuter = bvNone
      Caption = '7'
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -48
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 9
      OnMouseDown = P11MouseDown
      OnMouseMove = P12MouseMove
    end
    object P4: TPanel
      Tag = 4
      Left = 410
      Top = 323
      Width = 60
      Height = 41
      Cursor = crHandPoint
      BevelOuter = bvNone
      Caption = '4'
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -48
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 10
      OnMouseDown = P11MouseDown
      OnMouseMove = P12MouseMove
    end
    object P5: TPanel
      Tag = 5
      Left = 340
      Top = 410
      Width = 60
      Height = 41
      Cursor = crHandPoint
      BevelOuter = bvNone
      Caption = '5'
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -48
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 11
      OnMouseDown = P11MouseDown
      OnMouseMove = P12MouseMove
    end
    object HONEVPANEL: TPanel
      Left = 88
      Top = 236
      Width = 345
      Height = 41
      BevelOuter = bvNone
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -35
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 12
    end
    object EVCOMBO: TComboBox
      Left = 200
      Top = 168
      Width = 121
      Height = 52
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -37
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ItemHeight = 44
      ParentFont = False
      TabOrder = 13
      OnChange = EVCOMBOChange
    end
    object HOOKEGOMB: TBitBtn
      Left = 144
      Top = 280
      Width = 233
      Height = 33
      Cursor = crHandPoint
      Caption = 'H'#211'NAP RENDBEN'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 14
      OnClick = HOOKEGOMBClick
    end
    object HOMEGSEMGOMB: TBitBtn
      Left = 144
      Top = 320
      Width = 233
      Height = 25
      Cursor = crHandPoint
      Caption = 'M'#201'GSEM'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 15
      OnClick = HOMEGSEMGOMBClick
    end
    object BitBtn1: TBitBtn
      Left = 144
      Top = 352
      Width = 233
      Height = 25
      Cursor = crHandPoint
      Cancel = True
      Caption = 'KIL'#201'P'#201'S A PROGRAMB'#211'L'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 16
      OnClick = BitBtn1Click
    end
  end
  object Panel2: TPanel
    Left = 56
    Top = 8
    Width = 761
    Height = 33
    BevelOuter = bvNone
    Caption = 'HAVI BESZ'#193'MOL'#211' EXCELT'#193'BLA  ELK'#201'SZ'#205'T'#201'SE '
    Color = 4539717
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWhite
    Font.Height = -29
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 1
  end
  object Panel3: TPanel
    Left = 176
    Top = 48
    Width = 513
    Height = 25
    BevelOuter = bvNone
    Caption = 'MELYIK H'#211'NAPR'#211'L K'#201'SZ'#205'TSEK EXCEL-T'#193'BL'#193'T'
    Color = 4539717
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWhite
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 2
  end
  object RECQUERY: TIBQuery
    Database = RECDBASE
    Transaction = RECTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 16
    Top = 520
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
    Left = 48
    Top = 520
  end
  object RECTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = RECDBASE
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    AutoStopAction = saNone
    Left = 80
    Top = 520
  end
  object ACQUERY: TIBQuery
    Database = ACDBASE
    Transaction = ACTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 16
    Top = 560
  end
  object ACDBASE: TIBDatabase
    DatabaseName = 'C:\CARTCASH\DATABASE\ARTCASH.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = ACTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 48
    Top = 560
  end
  object ACTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = ACDBASE
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    AutoStopAction = saNone
    Left = 80
    Top = 560
  end
  object BESZQUERY: TIBQuery
    Database = BESZDBASE
    Transaction = BESZTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 16
    Top = 104
  end
  object BESZDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\BESZAMOLO.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = BESZTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 48
    Top = 104
  end
  object BESZTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = BESZDBASE
    AutoStopAction = saNone
    Left = 80
    Top = 104
  end
end
