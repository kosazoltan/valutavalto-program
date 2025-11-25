object GETPLOMBASZAM: TGETPLOMBASZAM
  Left = 388
  Top = 236
  BorderStyle = bsNone
  Caption = 'GETPLOMBASZAM'
  ClientHeight = 147
  ClientWidth = 523
  Color = clGreen
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
    Width = 521
    Height = 144
    BevelOuter = bvNone
    Color = clGreen
    TabOrder = 0
    object Shape1: TShape
      Left = 0
      Top = 0
      Width = 521
      Height = 144
      Align = alClient
      Brush.Color = 13697023
      Pen.Color = clRed
      Pen.Width = 5
    end
    object Label2: TLabel
      Left = 24
      Top = 16
      Width = 121
      Height = 19
      Caption = 'T'#193'RSP'#201'NZT'#193'R:'
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentColor = False
      ParentFont = False
      Transparent = True
    end
    object Label3: TLabel
      Left = 16
      Top = 40
      Width = 132
      Height = 19
      Caption = 'SZ'#193'LL'#205'T'#211' NEVE:'
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentColor = False
      ParentFont = False
      Transparent = True
    end
    object Label4: TLabel
      Left = 32
      Top = 64
      Width = 115
      Height = 19
      Caption = 'PLOMBASZ'#193'M:'
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentColor = False
      ParentFont = False
      Transparent = True
    end
    object Label5: TLabel
      Left = 40
      Top = 88
      Width = 107
      Height = 19
      Caption = 'MEGJEGYZ'#201'S'
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentColor = False
      ParentFont = False
      Transparent = True
    end
    object SZALLNEVEDIT: TEdit
      Left = 152
      Top = 35
      Width = 337
      Height = 29
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      MaxLength = 20
      ParentFont = False
      TabOrder = 0
      Text = 'SZALLNEVEDIT'
      OnEnter = SZALLNEVEDITEnter
      OnExit = SZALLNEVEDITExit
      OnKeyDown = SZALLNEVEDITKeyDown
    end
    object PLOMBAEDIT: TEdit
      Left = 152
      Top = 60
      Width = 337
      Height = 29
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      MaxLength = 10
      ParentFont = False
      TabOrder = 1
      Text = 'PLOMBAEDIT'
      OnEnter = SZALLNEVEDITEnter
      OnExit = SZALLNEVEDITExit
      OnKeyDown = PLOMBAEDITKeyDown
    end
    object MEGJEGYZESEDIT: TEdit
      Left = 152
      Top = 84
      Width = 337
      Height = 29
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      MaxLength = 25
      ParentFont = False
      TabOrder = 2
      Text = 'MEGJEGYZESEDIT'
      OnEnter = SZALLNEVEDITEnter
      OnExit = SZALLNEVEDITExit
      OnKeyDown = MEGJEGYZESEDITKeyDown
    end
    object KONYVELHETOGOMB: TBitBtn
      Left = 152
      Top = 116
      Width = 161
      Height = 20
      Cursor = crHandPoint
      Caption = 'K'#214'NYVELHET'#336
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -13
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 3
      OnClick = KONYVELHETOGOMBClick
    end
    object MEGSEMGOMB: TBitBtn
      Tag = 116
      Left = 328
      Top = 116
      Width = 161
      Height = 20
      Cursor = crHandPoint
      Caption = 'M'#201'GSEM'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -13
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 4
      OnClick = MEGSEMGOMBClick
    end
    object TARSSZAMPANEL: TPanel
      Left = 152
      Top = 12
      Width = 54
      Height = 21
      Caption = 'TARSSZAMPANEL'
      Color = clRed
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 5
    end
    object TARSNEVPANEL: TPanel
      Left = 208
      Top = 12
      Width = 281
      Height = 21
      Caption = 'TARSNEVPANEL'
      Color = clRed
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 6
    end
  end
  object VALUTAQUERY: TIBQuery
    Database = VALUTADBASE
    Transaction = VALUTATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 336
    Top = 48
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
    Left = 368
    Top = 48
  end
  object VALUTATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALUTADBASE
    AutoStopAction = saNone
    Left = 400
    Top = 48
  end
end
