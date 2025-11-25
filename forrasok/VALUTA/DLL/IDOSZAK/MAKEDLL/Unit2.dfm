object HONAPKEROFORM: THONAPKEROFORM
  Left = 214
  Top = 156
  BorderStyle = bsNone
  Caption = 'HONAPKEROFORM'
  ClientHeight = 162
  ClientWidth = 544
  Color = clTeal
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 540
    Height = 160
    BevelOuter = bvNone
    Color = clBlack
    TabOrder = 0
    object Shape1: TShape
      Left = 8
      Top = 8
      Width = 529
      Height = 145
      Brush.Color = clOlive
    end
    object Label1: TLabel
      Left = 40
      Top = 16
      Width = 465
      Height = 36
      Caption = 'ADJA MEG A K'#201'RT ID'#214'SZAKOT'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clYellow
      Font.Height = -32
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Label2: TLabel
      Left = 370
      Top = 64
      Width = 56
      Height = 29
      Caption = '-T'#211'L'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clYellow
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      Transparent = True
    end
    object Label3: TLabel
      Left = 488
      Top = 64
      Width = 32
      Height = 29
      Caption = '-IG'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clYellow
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      Transparent = True
    end
    object EVCOMBO: TComboBox
      Left = 40
      Top = 64
      Width = 73
      Height = 32
      Cursor = crHandPoint
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -19
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ItemHeight = 24
      ParentFont = False
      TabOrder = 3
      TabStop = False
      Text = '2008'
      OnChange = HOCOMBOChange
    end
    object HOCOMBO: TComboBox
      Left = 123
      Top = 64
      Width = 177
      Height = 32
      Cursor = crHandPoint
      DropDownCount = 12
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -19
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ItemHeight = 24
      ParentFont = False
      TabOrder = 2
      TabStop = False
      Text = 'SZEPTEMBER'
      OnChange = HOCOMBOChange
    end
    object IDSZOKEGOMB: TBitBtn
      Left = 24
      Top = 112
      Width = 161
      Height = 25
      Cursor = crHandPoint
      Caption = 'ID'#214'SZAK RENDBEN'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 4
      OnClick = IDSZOKEGOMBClick
      OnEnter = IDSZOKEGOMBEnter
      OnExit = IDSZOKEGOMBExit
      OnMouseMove = IDSZOKEGOMBMouseMove
    end
    object IDSZCANCELGOMB: TBitBtn
      Left = 360
      Top = 112
      Width = 161
      Height = 25
      Cursor = crHandPoint
      Caption = 'M'#201'GSEM'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 5
      OnClick = IDSZCANCELGOMBClick
      OnEnter = IDSZOKEGOMBEnter
      OnExit = IDSZOKEGOMBExit
      OnMouseMove = IDSZOKEGOMBMouseMove
    end
    object TOLNAPCOMBO: TComboBox
      Left = 312
      Top = 64
      Width = 57
      Height = 32
      DropDownCount = 15
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -19
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ItemHeight = 24
      ParentFont = False
      TabOrder = 1
      TabStop = False
      Text = '33'
      OnChange = TOLNAPCOMBOChange
    end
    object IGNAPCOMBO: TComboBox
      Left = 432
      Top = 64
      Width = 49
      Height = 32
      DropDownCount = 15
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -19
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ItemHeight = 24
      ParentFont = False
      TabOrder = 0
      TabStop = False
      Text = '30'
      OnChange = IGNAPCOMBOChange
    end
    object MAINAPGOMB: TBitBtn
      Left = 192
      Top = 112
      Width = 161
      Height = 25
      Cursor = crHandPoint
      Caption = 'CSAK A MAI NAP'
      TabOrder = 6
      OnClick = MAINAPGOMBClick
      OnEnter = IDSZOKEGOMBEnter
      OnExit = IDSZOKEGOMBExit
      OnMouseMove = IDSZOKEGOMBMouseMove
    end
  end
  object VALUTAQUERY: TIBQuery
    Database = VALUTADBASE
    Transaction = VALUTATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 216
    Top = 24
  end
  object VALUTADBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = VALUTATRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 248
    Top = 24
  end
  object VALUTATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALUTADBASE
    AutoStopAction = saNone
    Left = 280
    Top = 24
  end
end
