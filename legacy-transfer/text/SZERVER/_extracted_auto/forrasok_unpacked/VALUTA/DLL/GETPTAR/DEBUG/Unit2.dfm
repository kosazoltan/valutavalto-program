object PENZTARVALASZTOFORM: TPENZTARVALASZTOFORM
  Left = 262
  Top = 117
  AlphaBlendValue = 200
  BorderIcons = []
  BorderStyle = bsNone
  BorderWidth = 5
  ClientHeight = 522
  ClientWidth = 653
  Color = clWhite
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
  object Shape1: TShape
    Left = 0
    Top = 0
    Width = 653
    Height = 522
    Align = alClient
    Pen.Color = clRed
    Pen.Width = 5
  end
  object Label1: TLabel
    Left = 56
    Top = 16
    Width = 561
    Height = 43
    Caption = 'V'#193'LASSZA KI A T'#193'RSP'#201'NZT'#193'RT'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clBlack
    Font.Height = -37
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object PTARVALCANCELGOMB: TBitBtn
    Left = 240
    Top = 480
    Width = 185
    Height = 25
    Cursor = crHandPoint
    Cancel = True
    Caption = 'NEM V'#193'LASZTOK'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clBlack
    Font.Height = -15
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 0
    OnClick = PTARVALCANCELGOMBClick
  end
  object PTARVALOKEGOMB: TBitBtn
    Left = 48
    Top = 480
    Width = 185
    Height = 25
    Cursor = crHandPoint
    Caption = 'EZT V'#193'LASZTOM'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clBlack
    Font.Height = -15
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 1
    OnClick = penztarracsDblClick
  end
  object PENZTARRACS: TDBGrid
    Left = 12
    Top = 72
    Width = 620
    Height = 401
    Cursor = crHandPoint
    BorderStyle = bsNone
    Color = clWhite
    DataSource = PENZTARSOURCE
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clGreen
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    Options = [dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgConfirmDelete, dgCancelOnExit]
    ParentFont = False
    ReadOnly = True
    TabOrder = 2
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'MS Sans Serif'
    TitleFont.Style = []
    OnDblClick = penztarracsDblClick
    OnKeyDown = PENZTARRACSKeyDown
    Columns = <
      item
        Alignment = taCenter
        DropDownRows = 50
        Expanded = False
        FieldName = 'PENZTARKOD'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -19
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        Title.Alignment = taCenter
        Title.Caption = 'SZ'#193'M'
        Title.Color = 4539717
        Title.Font.Charset = DEFAULT_CHARSET
        Title.Font.Color = clWhite
        Title.Font.Height = -23
        Title.Font.Name = 'MS Sans Serif'
        Title.Font.Style = []
        Width = 134
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'PENZTARNEV'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -19
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        Title.Alignment = taCenter
        Title.Caption = 'MEGNEVEZ'#201'S'
        Title.Color = 4539717
        Title.Font.Charset = DEFAULT_CHARSET
        Title.Font.Color = clWhite
        Title.Font.Height = -23
        Title.Font.Name = 'MS Sans Serif'
        Title.Font.Style = []
        Width = 479
        Visible = True
      end>
  end
  object UJPENZTARGOMB: TBitBtn
    Left = 432
    Top = 480
    Width = 185
    Height = 25
    Cursor = crHandPoint
    Caption = #218'J P'#201'NZT'#193'R FELV'#201'TELE'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -15
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 3
    OnClick = UJPENZTARGOMBClick
  end
  object UJPENZTARPANEL: TPanel
    Left = -1650
    Top = 180
    Width = 630
    Height = 281
    BevelOuter = bvNone
    TabOrder = 4
    Visible = False
    object Shape2: TShape
      Left = 0
      Top = 0
      Width = 630
      Height = 281
      Align = alClient
      Pen.Color = clRed
      Pen.Width = 5
    end
    object Label2: TLabel
      Left = 88
      Top = 32
      Width = 385
      Height = 36
      Caption = #218'J P'#201'NZT'#193'R FELV'#201'TELE'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -32
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Label3: TLabel
      Left = 24
      Top = 104
      Width = 205
      Height = 19
      Caption = 'P'#201'NZT'#193'R SZ'#193'MA ................:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Label4: TLabel
      Left = 24
      Top = 136
      Width = 206
      Height = 19
      Caption = 'P'#201'NZT'#193'R MEGNEVEZ'#201'SE:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Label5: TLabel
      Left = 24
      Top = 168
      Width = 210
      Height = 19
      Caption = 'P'#201'NZT'#193'R C'#205'ME ..............:.....:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Label6: TLabel
      Left = 24
      Top = 200
      Width = 211
      Height = 19
      Caption = 'TELEFONSZ'#193'MA ..................:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object PSZAMEDIT: TEdit
      Tag = 1
      Left = 240
      Top = 100
      Width = 57
      Height = 27
      BorderStyle = bsNone
      CharCase = ecUpperCase
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      MaxLength = 4
      ParentFont = False
      TabOrder = 0
      Text = '2345'
      OnEnter = PSZAMEDITEnter
      OnExit = PSZAMEDITExit
      OnKeyDown = PSZAMEDITKeyDown
    end
    object PNEVEDIT: TEdit
      Tag = 2
      Left = 240
      Top = 136
      Width = 345
      Height = 27
      BorderStyle = bsNone
      CharCase = ecUpperCase
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      MaxLength = 30
      ParentFont = False
      TabOrder = 1
      Text = 'ASDERFGTZXDERFGTZTRXSDFGHZUTXX'
      OnEnter = PSZAMEDITEnter
      OnExit = PSZAMEDITExit
      OnKeyDown = PSZAMEDITKeyDown
    end
    object PCIMEDIT: TEdit
      Tag = 3
      Left = 240
      Top = 167
      Width = 377
      Height = 24
      BorderStyle = bsNone
      CharCase = ecUpperCase
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      MaxLength = 40
      ParentFont = False
      TabOrder = 2
      Text = 'WERDFTGZDXCDFGVHGTRXCVBNHZTRFXCVBNJHZTXX'
      OnEnter = PSZAMEDITEnter
      OnExit = PSZAMEDITExit
      OnKeyDown = PSZAMEDITKeyDown
    end
    object PTELEDIT: TEdit
      Tag = 4
      Left = 240
      Top = 197
      Width = 241
      Height = 27
      BorderStyle = bsNone
      CharCase = ecUpperCase
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      MaxLength = 20
      ParentFont = False
      TabOrder = 3
      Text = 'ASDERFTGZXDFRTGHZUXX'
      OnEnter = PSZAMEDITEnter
      OnExit = PSZAMEDITExit
      OnKeyDown = PSZAMEDITKeyDown
    end
    object ujptokegomb: TBitBtn
      Left = 96
      Top = 240
      Width = 185
      Height = 25
      Cursor = crHandPoint
      Caption = #218'J P'#201'NZT'#193'R RENDBEN'
      TabOrder = 4
      OnClick = ujptokegombClick
    end
    object UJPTMEGSEMGOMB: TBitBtn
      Left = 296
      Top = 240
      Width = 185
      Height = 25
      Cursor = crHandPoint
      Caption = 'VISSZA A V'#193'LASZT'#193'SHOZ'
      TabOrder = 5
      OnClick = UJPTMEGSEMGOMBClick
    end
  end
  object TRBBEKEROPANEL: TPanel
    Left = -1200
    Top = 200
    Width = 393
    Height = 177
    BevelOuter = bvNone
    TabOrder = 5
    Visible = False
    object Shape3: TShape
      Left = 0
      Top = 0
      Width = 393
      Height = 177
      Align = alClient
      Brush.Color = clMoneyGreen
      Brush.Style = bsDiagCross
      Pen.Width = 2
    end
    object Label7: TLabel
      Left = 32
      Top = 24
      Width = 335
      Height = 24
      Caption = 'K'#201'REM A TRB P'#201'NZT'#193'R SZ'#193'M'#193'T'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
      Transparent = True
    end
    object TRBPTEDIT: TEdit
      Left = 168
      Top = 64
      Width = 65
      Height = 40
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -27
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 0
      Text = '254'
      OnEnter = TRBPTEDITEnter
      OnExit = TRBPTEDITExit
      OnKeyDown = TRBPTEDITKeyDown
    end
    object TRBPTOKEGOMB: TBitBtn
      Left = 24
      Top = 128
      Width = 161
      Height = 25
      Cursor = crHandPoint
      Caption = 'P'#201'NZT'#193'RSZ'#193'M RENDBEN'
      TabOrder = 1
      OnClick = TRBPTOKEGOMBClick
    end
    object TRBPTMEGSEMGOMB: TBitBtn
      Left = 200
      Top = 128
      Width = 161
      Height = 25
      Cursor = crHandPoint
      Caption = 'M'#201'GSEM ADOM MEG'
      TabOrder = 2
      OnClick = TRBPTMEGSEMGOMBClick
    end
  end
  object PENZTARSOURCE: TDataSource
    DataSet = VALUTAQUERY
    Left = 32
    Top = 160
  end
  object VALUTADBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = VALUTATRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 64
    Top = 216
  end
  object VALUTATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALUTADBASE
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    AutoStopAction = saNone
    Left = 96
    Top = 216
  end
  object VALUTAQUERY: TIBQuery
    Database = VALUTADBASE
    Transaction = VALUTATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 32
    Top = 216
  end
end
