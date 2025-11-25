object Form2: TForm2
  Left = 192
  Top = 124
  BorderStyle = bsNone
  Caption = 'Form1'
  ClientHeight = 480
  ClientWidth = 388
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object ALAPPANEL: TPanel
    Left = 0
    Top = 0
    Width = 385
    Height = 473
    BevelOuter = bvNone
    Color = 11599871
    TabOrder = 0
    object Shape2: TShape
      Left = 0
      Top = 0
      Width = 385
      Height = 473
      Align = alClient
      Brush.Color = 11599871
      Pen.Color = clRed
      Pen.Width = 2
    end
    object Label4: TLabel
      Left = 8
      Top = 440
      Width = 41
      Height = 13
      Caption = 'M'#201'RET:'
    end
    object n1LABEL: TLabel
      Left = 104
      Top = 88
      Width = 190
      Height = 42
      Caption = 'Exclusive'
      Font.Charset = ANSI_CHARSET
      Font.Color = clSilver
      Font.Height = -35
      Font.Name = 'Stencil'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object N2LABEL: TLabel
      Left = 104
      Top = 168
      Width = 140
      Height = 42
      Caption = 'Change'
      Font.Charset = ANSI_CHARSET
      Font.Color = clSilver
      Font.Height = -35
      Font.Name = 'Stencil'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label7: TLabel
      Left = 104
      Top = 248
      Width = 82
      Height = 42
      Caption = 'Kft.'
      Font.Charset = ANSI_CHARSET
      Font.Color = clSilver
      Font.Height = -35
      Font.Name = 'Stencil'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object KIJELZO: TPaintBox
      Left = 16
      Top = 40
      Width = 73
      Height = 350
      OnPaint = KijelzoPaint
    end
    object MERETPANEL: TPanel
      Left = 56
      Top = 424
      Width = 33
      Height = 41
      BevelOuter = bvNone
      Color = 11599871
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -24
      Font.Name = 'Arial Narrow'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 3
    end
    object CSUSZO: TTrackBar
      Left = 8
      Top = 392
      Width = 369
      Height = 33
      Max = 30
      Min = 3
      Orientation = trHorizontal
      Frequency = 3
      Position = 3
      SelEnd = 0
      SelStart = 0
      TabOrder = 0
      TickMarks = tmTopLeft
      TickStyle = tsAuto
    end
    object TOVABBGOMB: TBitBtn
      Left = 96
      Top = 440
      Width = 137
      Height = 25
      Cursor = crHandPoint
      Cancel = True
      Caption = 'TOV'#193'BB'
      TabOrder = 1
      OnClick = TOVABBGOMBClick
    end
    object NEXTGOMB: TBitBtn
      Left = 240
      Top = 440
      Width = 137
      Height = 25
      Cursor = crHandPoint
      Caption = 'K'#214'VETKEZ'#336' QR-K'#211'D'
      TabOrder = 4
      Visible = False
      OnClick = NEXTGOMBClick
    end
    object QRTAKARO: TPanel
      Left = -777
      Top = 5
      Width = 640
      Height = 640
      BevelOuter = bvNone
      Color = clWhite
      TabOrder = 2
      Visible = False
      object Shape1: TShape
        Left = 144
        Top = 152
        Width = 337
        Height = 329
        Brush.Color = clRed
        Pen.Width = 3
        Shape = stCircle
      end
      object Label1: TLabel
        Left = 240
        Top = 240
        Width = 150
        Height = 29
        Caption = 'OLVASSA BE'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clYellow
        Font.Height = -24
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        Transparent = True
      end
      object Label2: TLabel
        Left = 160
        Top = 304
        Width = 305
        Height = 29
        Caption = 'A MINDJ'#193'RT MEGJELEN'#336
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clYellow
        Font.Height = -24
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        Transparent = True
      end
      object Label3: TLabel
        Left = 256
        Top = 368
        Width = 128
        Height = 29
        Caption = 'QR-K'#211'DOT'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clYellow
        Font.Height = -24
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        Transparent = True
      end
    end
    object FOCIMPANEL: TPanel
      Left = 16
      Top = 4
      Width = 353
      Height = 33
      BevelOuter = bvNone
      Color = 11599871
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 5
    end
  end
  object VALUTAQUERY: TIBQuery
    Database = VALUTADBASE
    Transaction = VALUTATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 144
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
    Left = 176
    Top = 48
  end
  object VALUTATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALUTADBASE
    AutoStopAction = saNone
    Left = 208
    Top = 48
  end
end
