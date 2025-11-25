object UJKONVERZIO: TUJKONVERZIO
  Left = 192
  Top = 124
  BorderStyle = bsNone
  Caption = 'UJKONVERZIO'
  ClientHeight = 356
  ClientWidth = 474
  Color = clRed
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object ALAPPANEL: TPanel
    Left = 0
    Top = 0
    Width = 473
    Height = 353
    BevelOuter = bvNone
    TabOrder = 0
    object Shape1: TShape
      Left = 0
      Top = 0
      Width = 473
      Height = 353
      Align = alClient
      Pen.Color = clRed
      Pen.Width = 5
    end
    object Label1: TLabel
      Left = 80
      Top = 40
      Width = 304
      Height = 33
      Caption = 'VALUTA KONVERZI'#211
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -29
      Font.Name = 'Arial Rounded MT Bold'
      Font.Style = []
      ParentFont = False
      Transparent = True
    end
    object VASAROKEpanel: TPanel
      Left = 320
      Top = 96
      Width = 129
      Height = 33
      Caption = 'Rendben'
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 0
      Visible = False
    end
    object VASARINFOPANEL: TPanel
      Left = 24
      Top = 136
      Width = 289
      Height = 33
      Caption = 'Megv'#225's'#225'rolt valuta(k) forint '#233'rt'#233'ke:'
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 1
      Visible = False
    end
    object VASARFTPANEL: TPanel
      Left = 320
      Top = 136
      Width = 129
      Height = 33
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 2
      Visible = False
    end
    object ELADASINFOPANEL: TPanel
      Left = 24
      Top = 216
      Width = 289
      Height = 33
      Caption = 'Konvert'#225'lt valuta t'#233'nyleges '#233'rt'#233'ke:'
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 3
      Visible = False
    end
    object ELADASFTPANEL: TPanel
      Left = 320
      Top = 216
      Width = 129
      Height = 33
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 4
      Visible = False
    end
    object VISSZAJAROPANEL: TPanel
      Left = 24
      Top = 256
      Width = 289
      Height = 33
      Caption = 'A vev'#337'nek visszaj'#225'r'
      Color = 16756991
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 5
      Visible = False
    end
    object VISSZAJAROFTPANEL: TPanel
      Left = 320
      Top = 256
      Width = 129
      Height = 33
      Color = clRed
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 6
      Visible = False
    end
    object RETURNGOMB: TBitBtn
      Left = 128
      Top = 304
      Width = 209
      Height = 33
      Cursor = crHandPoint
      Caption = 'Vissza a f'#337'men'#252're'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 7
      OnClick = RETURNGOMBClick
    end
    object VASARGOMB: TBitBtn
      Left = 24
      Top = 96
      Width = 289
      Height = 33
      Cursor = crHandPoint
      Caption = 'Valuta(k) megv'#225's'#225'rol'#225'sa'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 8
      OnClick = VASARGOMBClick
    end
    object ELADASGOMB: TBitBtn
      Left = 24
      Top = 176
      Width = 425
      Height = 33
      Cursor = crHandPoint
      Caption = 'Konvert'#225'lt valuta elad'#225'sa a fenti '#233'rt'#233'kben'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 9
      OnClick = ELADASGOMBClick
    end
  end
  object MEGHIUSULTPANEL: TPanel
    Left = -1500
    Top = 96
    Width = 425
    Height = 201
    BevelOuter = bvNone
    Color = 13697023
    TabOrder = 1
    object Label2: TLabel
      Left = 48
      Top = 24
      Width = 366
      Height = 32
      Caption = 'KONVERZI'#211' MEGHI'#218'SULT !'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -27
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label3: TLabel
      Left = 64
      Top = 72
      Width = 331
      Height = 24
      Caption = 'KI KELL FIZETNI AZ '#220'GYF'#201'LNEK'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object FIZETENDOPANEL: TPanel
      Left = 64
      Top = 128
      Width = 313
      Height = 41
      BevelOuter = bvNone
      Caption = '123,456,000 forintot'
      Color = 13697023
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clRed
      Font.Height = -29
      Font.Name = 'Arial'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 0
    end
  end
  object VALUTAQUERY: TIBQuery
    Database = VALUTADBASE
    Transaction = VALUTATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 16
    Top = 8
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
    Left = 48
    Top = 8
  end
  object VALUTATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALUTADBASE
    AutoStopAction = saNone
    Left = 80
    Top = 8
  end
end
