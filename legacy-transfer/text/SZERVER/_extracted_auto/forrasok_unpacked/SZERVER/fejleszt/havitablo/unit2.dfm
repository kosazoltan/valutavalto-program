object EXCELKESZITES: TEXCELKESZITES
  Left = 192
  Top = 125
  BorderStyle = bsNone
  Caption = 'EXCELKESZITES'
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
  object Label1: TLabel
    Left = 64
    Top = 16
    Width = 198
    Height = 29
    Caption = 'EXCELT'#193'BLA K'#201'SZIT'#201'S'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -24
    Font.Name = 'Impact'
    Font.Style = []
    ParentFont = False
  end
  object Memo: TMemo
    Left = 16
    Top = 56
    Width = 297
    Height = 321
    BorderStyle = bsNone
    Color = 11599871
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Calibri'
    Font.Style = [fsItalic]
    Lines.Strings = (
      '')
    ParentFont = False
    TabOrder = 0
  end
  object EXCELQUITGOMB: TBitBtn
    Left = 88
    Top = 392
    Width = 153
    Height = 25
    Cursor = crHandPoint
    Caption = 'KIL'#201'P'
    TabOrder = 1
    Visible = False
    OnClick = EXCELQUITGOMBClick
  end
  object INFOTABLA: TPanel
    Left = 8
    Top = 232
    Width = 313
    Height = 153
    BevelOuter = bvNone
    Color = clWhite
    TabOrder = 2
    Visible = False
    object Label2: TLabel
      Left = 24
      Top = 32
      Width = 273
      Height = 18
      Caption = 'AZ EXCELT'#193'BL'#193'T ELMENTETTEM'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object Label3: TLabel
      Left = 120
      Top = 120
      Width = 57
      Height = 18
      Caption = 'N'#201'VEN'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object XLSNEVTABLA: TPanel
      Left = 0
      Top = 64
      Width = 313
      Height = 41
      BevelOuter = bvNone
      Caption = 'C:\HAVITABLO\EXCEL\HAVITAB2201,XLS'
      Color = clWhite
      Font.Charset = ANSI_CHARSET
      Font.Color = clRed
      Font.Height = -19
      Font.Name = 'Impact'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
    end
  end
  object KILEPO: TTimer
    Enabled = False
    Interval = 120
    OnTimer = KilepoTimer
    Left = 16
    Top = 16
  end
end
