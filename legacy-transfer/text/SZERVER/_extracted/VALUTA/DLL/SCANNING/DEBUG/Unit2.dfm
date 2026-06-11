object Form2: TForm2
  Left = 192
  Top = 114
  BorderStyle = bsNone
  Caption = 'Form2'
  ClientHeight = 602
  ClientWidth = 854
  Color = 4210752
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object SCANPANEL: TPanel
    Left = -1800
    Top = 64
    Width = 417
    Height = 193
    BevelOuter = bvNone
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 0
    Visible = False
    object Shape1: TShape
      Left = 0
      Top = 0
      Width = 417
      Height = 193
      Align = alClient
      Brush.Color = clRed
      Pen.Width = 4
    end
    object Label1: TLabel
      Left = 32
      Top = 32
      Width = 383
      Height = 28
      Caption = 'Siker'#252'lt az okm'#225'nyok beolvas'#225'sa '
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clYellow
      Font.Height = -24
      Font.Name = 'Arial'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object SCANOKEGOMB: TBitBtn
      Left = 48
      Top = 80
      Width = 329
      Height = 25
      Caption = 'Igen - Sikeresen beolvastam'
      TabOrder = 0
      OnClick = SCANOKEGOMBClick
    end
    object RETRYGOMB: TBitBtn
      Left = 48
      Top = 112
      Width = 329
      Height = 25
      Caption = 'Nem siker'#252'lt  '#250'jta megpr'#243'b'#225'lom'
      TabOrder = 1
      OnClick = RETRYGOMBClick
    end
    object CANCELGOMB: TBitBtn
      Left = 48
      Top = 144
      Width = 329
      Height = 25
      Caption = #220'gyf'#233'l m'#233'gsem k'#233'ri a v'#225'lt'#225'st'
      TabOrder = 2
      OnClick = CANCELGOMBClick
    end
  end
  object FIGYELEMPANEL: TPanel
    Left = -900
    Top = 384
    Width = 457
    Height = 192
    Caption = 'FELK'#201'SZ'#220'L'#201'S A SCANNEL'#201'SRE'
    Color = clYellow
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clRed
    Font.Height = -29
    Font.Name = 'Gill Sans Ultra Bold Condensed'
    Font.Style = []
    ParentFont = False
    TabOrder = 1
    Visible = False
  end
  object VALUTAQUERY: TIBQuery
    Database = VALUTADBASE
    Transaction = valutatranz
    BufferChunks = 1000
    CachedUpdates = False
    Left = 576
    Top = 80
  end
  object VALUTADBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = valutatranz
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 616
    Top = 80
  end
  object valutatranz: TIBTransaction
    Active = False
    DefaultDatabase = VALUTADBASE
    AutoStopAction = saNone
    Left = 656
    Top = 80
  end
end
