object SUPERVISORFORM: TSUPERVISORFORM
  Left = 215
  Top = 114
  BorderStyle = bsNone
  Caption = 'SUPERVISORFORM'
  ClientHeight = 418
  ClientWidth = 610
  Color = clGray
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
    Width = 609
    Height = 417
    BevelOuter = bvNone
    Color = clBlack
    TabOrder = 0
    object Shape1: TShape
      Left = 160
      Top = 8
      Width = 377
      Height = 393
      Brush.Color = 5592405
      Pen.Width = 5
    end
    object Label2: TLabel
      Left = 40
      Top = 56
      Width = 289
      Height = 31
      Caption = 'SUPERVISOR MEN'#220'JE'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clYellow
      Font.Height = -27
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Shape2: TShape
      Left = 24
      Top = 104
      Width = 329
      Height = 249
      Brush.Color = 10066329
      Pen.Width = 2
      Shape = stRoundRect
    end
    object BitBtn1: TBitBtn
      Left = 40
      Top = 184
      Width = 297
      Height = 25
      Cursor = crHandPoint
      Caption = 'LOGFILE KIOLVAS'#193'SA'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
      OnClick = BitBtn1Click
    end
    object BitBtn2: TBitBtn
      Left = 40
      Top = 152
      Width = 297
      Height = 25
      Cursor = crHandPoint
      Caption = 'C'#205'MLETEK BE'#193'LL'#205'T'#193'SA'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
      OnClick = CIMLETSETUPGOMBClick
    end
    object BitBtn3: TBitBtn
      Left = 40
      Top = 312
      Width = 297
      Height = 25
      Cursor = crHandPoint
      Caption = 'KIL'#201'P'#201'S A SUPERVISORI MEN'#220'B'#336'L'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 5
      OnClick = ESCAPEGOMBClick
    end
    object XTRANZGOMB: TBitBtn
      Left = 40
      Top = 120
      Width = 297
      Height = 25
      Cursor = crHandPoint
      Caption = 'EXTRA TRANZAKCI'#211'S D'#205'JAK'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      OnClick = XTRANZGOMBClick
    end
    object checklistgomb: TBitBtn
      Left = 40
      Top = 248
      Width = 297
      Height = 25
      Cursor = crHandPoint
      Caption = 'CHECKLISTA ELLEN'#336'RZ'#201'SE'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 3
      OnClick = checklistgombClick
    end
    object BitBtn4: TBitBtn
      Left = 40
      Top = 280
      Width = 297
      Height = 25
      Cursor = crHandPoint
      Caption = 'P'#201'NZT'#193'RI SZ'#220'NETEK'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 4
      OnClick = BitBtn4Click
    end
    object SZUNETPANEL: TPanel
      Left = 376
      Top = -160
      Width = 593
      Height = 401
      Color = 5592405
      TabOrder = 6
      object Label1: TLabel
        Left = 136
        Top = 16
        Width = 355
        Height = 24
        Caption = 'A P'#201'NZT'#193'RI SZ'#220'NETEK LIST'#193'Z'#193'SA'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clYellow
        Font.Height = -21
        Font.Name = 'Times New Roman'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
      end
      object IBRACS: TDBGrid
        Left = 8
        Top = 80
        Width = 561
        Height = 313
        BorderStyle = bsNone
        Color = 5592405
        DataSource = IBSOURCE
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        Options = [dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgConfirmDelete, dgCancelOnExit]
        ParentFont = False
        TabOrder = 0
        TitleFont.Charset = DEFAULT_CHARSET
        TitleFont.Color = clWindowText
        TitleFont.Height = -11
        TitleFont.Name = 'MS Sans Serif'
        TitleFont.Style = []
        Columns = <
          item
            Alignment = taCenter
            Expanded = False
            FieldName = 'DATUM'
            Title.Alignment = taCenter
            Title.Caption = 'D'#193'TUM'
            Title.Font.Charset = DEFAULT_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -11
            Title.Font.Name = 'MS Sans Serif'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Alignment = taCenter
            Expanded = False
            FieldName = 'TOL'
            Title.Alignment = taCenter
            Title.Caption = 'MIKORT'#211'L'
            Title.Font.Charset = DEFAULT_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -11
            Title.Font.Name = 'MS Sans Serif'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Alignment = taCenter
            Expanded = False
            FieldName = 'IG'
            Title.Alignment = taCenter
            Title.Caption = 'MEDDIG'
            Title.Font.Charset = DEFAULT_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -11
            Title.Font.Name = 'MS Sans Serif'
            Title.Font.Style = [fsBold]
            Width = 100
            Visible = True
          end
          item
            Alignment = taCenter
            Expanded = False
            FieldName = 'MEGNEVEZES'
            Title.Alignment = taCenter
            Title.Caption = 'MEGNEVEZ'#201'S'
            Title.Font.Charset = DEFAULT_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -11
            Title.Font.Name = 'MS Sans Serif'
            Title.Font.Style = [fsBold]
            Width = 125
            Visible = True
          end
          item
            Alignment = taCenter
            Expanded = False
            FieldName = 'PENZTAROSNEV'
            Title.Alignment = taCenter
            Title.Caption = 'P'#201'NZT'#193'ROSN'#201'V'
            Title.Font.Charset = DEFAULT_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -11
            Title.Font.Name = 'MS Sans Serif'
            Title.Font.Style = [fsBold]
            Width = 131
            Visible = True
          end>
      end
      object VISSZAGOMB: TBitBtn
        Left = 216
        Top = 368
        Width = 161
        Height = 25
        Cursor = crHandPoint
        Cancel = True
        Caption = 'VISSZA'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Times New Roman'
        Font.Style = [fsItalic]
        ParentFont = False
        TabOrder = 1
        OnClick = VISSZAGOMBClick
      end
    end
    object BitBtn5: TBitBtn
      Left = 40
      Top = 216
      Width = 297
      Height = 25
      Cursor = crHandPoint
      Caption = 'OTP TERMINAL LOG OVAS'#193'SA'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 7
      OnClick = BitBtn5Click
    end
  end
  object ibdbase: TIBDatabase
    Connected = True
    DatabaseName = 'C:\VALUTA\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = IBTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 48
    Top = 8
  end
  object IBTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = ibdbase
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    AutoStopAction = saNone
    Left = 80
    Top = 8
  end
  object IBSOURCE: TDataSource
    DataSet = IBTABLA
    Left = 112
    Top = 8
  end
  object IBTABLA: TIBTable
    Database = ibdbase
    Transaction = IBTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    StoreDefs = True
    Left = 16
    Top = 8
  end
  object IBQuery: TIBQuery
    Database = ibdbase
    Transaction = IBTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 16
    Top = 48
  end
end
