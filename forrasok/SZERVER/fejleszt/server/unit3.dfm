object RENDSZERADATOK: TRENDSZERADATOK
  Left = 234
  Top = 289
  BorderStyle = bsNone
  Caption = 'Rendszeradatok karbantart'#225'sa'
  ClientHeight = 278
  ClientWidth = 570
  Color = 170
  TransparentColor = True
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
    Width = 569
    Height = 273
    BevelOuter = bvNone
    Color = 170
    TabOrder = 0
    object Shape1: TShape
      Left = 8
      Top = 8
      Width = 553
      Height = 257
      Brush.Color = 8421631
      Pen.Width = 2
    end
    object Label1: TLabel
      Left = 24
      Top = 48
      Width = 134
      Height = 19
      Caption = '1. P'#201'NZV'#193'LT'#211':    '
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clMaroon
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Label3: TLabel
      Left = 16
      Top = 176
      Width = 287
      Height = 19
      Caption = 'BANKI FORGALMAK P'#201'NZT'#193'RJELEI:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clMaroon
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Label5: TLabel
      Left = 176
      Top = 208
      Width = 166
      Height = 19
      Caption = 'E-MAILEK JELSZAVA:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clMaroon
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object ujlabel: TLabel
      Left = 456
      Top = 176
      Width = 25
      Height = 19
      Caption = #218'J:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clMaroon
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Label4: TLabel
      Left = 208
      Top = 16
      Width = 132
      Height = 22
      Caption = 'MEGNEVEZ'#201'S'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clMaroon
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Label6: TLabel
      Left = 432
      Top = 16
      Width = 110
      Height = 22
      Caption = 'AZONOS'#205'T'#211
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clMaroon
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Label2: TLabel
      Left = 24
      Top = 80
      Width = 118
      Height = 19
      Caption = '2. P'#201'NZV'#193'LT'#211':'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clMaroon
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Label7: TLabel
      Left = 24
      Top = 112
      Width = 113
      Height = 19
      Caption = '3. P'#201'NZV'#193'LT'#211
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clMaroon
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Label8: TLabel
      Left = 24
      Top = 144
      Width = 112
      Height = 19
      Caption = '4. '#201'KSZERH'#193'Z'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clMaroon
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object BANKJELBOX: TComboBox
      Left = 312
      Top = 168
      Width = 113
      Height = 27
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ItemHeight = 19
      ParentFont = False
      TabOrder = 0
      OnKeyDown = NEVEDITKeyDown
    end
    object VISSZAGOMB: TButton
      Left = 312
      Top = 232
      Width = 201
      Height = 25
      Cursor = crHandPoint
      Cancel = True
      Caption = 'VISSZA'
      ModalResult = 2
      TabOrder = 1
      OnClick = VISSZAGOMBClick
    end
    object NEVEDIT: TEdit
      Left = 152
      Top = 40
      Width = 249
      Height = 27
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 2
      OnEnter = NEVEDITEnter
      OnExit = NEVEDITExit
      OnKeyDown = NEVEDITKeyDown
    end
    object IDEDIT: TEdit
      Left = 424
      Top = 40
      Width = 121
      Height = 27
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 3
      OnEnter = NEVEDITEnter
      OnExit = NEVEDITExit
      OnKeyDown = NEVEDITKeyDown
    end
    object PWEDIT: TEdit
      Left = 352
      Top = 200
      Width = 193
      Height = 27
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 4
      OnEnter = NEVEDITEnter
      OnExit = NEVEDITExit
      OnKeyDown = NEVEDITKeyDown
    end
    object rogzitogomb: TBitBtn
      Left = 64
      Top = 232
      Width = 233
      Height = 25
      Cursor = crHandPoint
      Caption = 'M'#211'DOSIT'#193'SOK R'#214'GZIT'#201'SE'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 5
      OnClick = rogzitogombClick
    end
    object UJBANKJEL: TEdit
      Left = 496
      Top = 168
      Width = 49
      Height = 27
      CharCase = ecUpperCase
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      MaxLength = 3
      ParentFont = False
      TabOrder = 6
      OnEnter = NEVEDITEnter
      OnExit = NEVEDITExit
      OnKeyDown = UJBANKJELKeyDown
    end
    object NEVEDIT1: TEdit
      Left = 152
      Top = 72
      Width = 249
      Height = 27
      CharCase = ecUpperCase
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 7
      OnEnter = NEVEDITEnter
      OnExit = NEVEDITExit
      OnKeyDown = NEVEDITKeyDown
    end
    object IDEDIT1: TEdit
      Left = 424
      Top = 72
      Width = 121
      Height = 27
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 8
      OnEnter = NEVEDITEnter
      OnExit = NEVEDITExit
      OnKeyDown = NEVEDITKeyDown
    end
    object NEVEDIT2: TEdit
      Left = 152
      Top = 104
      Width = 249
      Height = 27
      CharCase = ecUpperCase
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 9
      OnEnter = NEVEDITEnter
      OnExit = NEVEDITExit
      OnKeyDown = NEVEDITKeyDown
    end
    object IDEDIT2: TEdit
      Left = 424
      Top = 104
      Width = 121
      Height = 27
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 10
      OnEnter = NEVEDITEnter
      OnExit = NEVEDITExit
      OnKeyDown = NEVEDITKeyDown
    end
    object NEVEDIT3: TEdit
      Left = 152
      Top = 136
      Width = 249
      Height = 27
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 11
    end
    object IDEDIT3: TEdit
      Left = 424
      Top = 136
      Width = 121
      Height = 27
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 12
    end
  end
  object RENDSZERTABLA: TIBTable
    Database = RENDSZERDBASE
    Transaction = RENDSZERTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    TableName = 'SYSTEM'
    Left = 8
    Top = 8
  end
  object RENDSZERDBASE: TIBDatabase
    DatabaseName = 'localhost:C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = RENDSZERTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 72
    Top = 8
  end
  object RENDSZERTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = RENDSZERDBASE
    AutoStopAction = saNone
    Left = 104
    Top = 8
  end
  object RENDSZERQUERY: TIBQuery
    Database = RENDSZERDBASE
    Transaction = RENDSZERTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 40
    Top = 8
  end
end
