import 'package:flutter/material.dart';
import '/backend/schema/structs/index.dart';
import '/backend/schema/enums/enums.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'flutter_flow/flutter_flow_util.dart';

class FFAppState extends ChangeNotifier {
  static FFAppState _instance = FFAppState._internal();

  factory FFAppState() {
    return _instance;
  }

  FFAppState._internal();

  static void reset() {
    _instance = FFAppState._internal();
  }

  Future initializePersistedState() async {
    prefs = await SharedPreferences.getInstance();
    _safeInit(() {
      _varVerNota = prefs.getBool('ff_varVerNota') ?? _varVerNota;
    });
    _safeInit(() {
      _varNome = prefs.getString('ff_varNome') ?? _varNome;
    });
    _safeInit(() {
      _varEmail = prefs.getString('ff_varEmail') ?? _varEmail;
    });
    _safeInit(() {
      _varPerfilIncompleto =
          prefs.getBool('ff_varPerfilIncompleto') ?? _varPerfilIncompleto;
    });
    _safeInit(() {
      _varLogginSecao = prefs.getBool('ff_varLogginSecao') ?? _varLogginSecao;
    });
    _safeInit(() {
      if (prefs.containsKey('ff_vrresendconfirm')) {
        try {
          final serializedData = prefs.getString('ff_vrresendconfirm') ?? '{}';
          _vrresendconfirm =
              DTnumerresendconfirmemailStruct.fromSerializableMap(
                  jsonDecode(serializedData));
        } catch (e) {
          print("Can't decode persisted data type. Error: $e.");
        }
      }
    });
    _safeInit(() {
      _agencyaprovvedconfig =
          prefs.getBool('ff_agencyaprovvedconfig') ?? _agencyaprovvedconfig;
    });
    _safeInit(() {
      if (prefs.containsKey('ff_appFilterPDVs')) {
        try {
          final serializedData = prefs.getString('ff_appFilterPDVs') ?? '{}';
          _appFilterPDVs = DtFILTERSPDVSStruct.fromSerializableMap(
              jsonDecode(serializedData));
        } catch (e) {
          print("Can't decode persisted data type. Error: $e.");
        }
      }
    });
  }

  void update(VoidCallback callback) {
    callback();
    notifyListeners();
  }

  late SharedPreferences prefs;

  String _varNavBarHome = '';
  String get varNavBarHome => _varNavBarHome;
  set varNavBarHome(String value) {
    _varNavBarHome = value;
  }

  String _varNavBarRH = '';
  String get varNavBarRH => _varNavBarRH;
  set varNavBarRH(String value) {
    _varNavBarRH = value;
  }

  String _varNavBarFinanceiro = '';
  String get varNavBarFinanceiro => _varNavBarFinanceiro;
  set varNavBarFinanceiro(String value) {
    _varNavBarFinanceiro = value;
  }

  String _varNavBarTarefas = '';
  String get varNavBarTarefas => _varNavBarTarefas;
  set varNavBarTarefas(String value) {
    _varNavBarTarefas = value;
  }

  String _varNavBarBuscar = '';
  String get varNavBarBuscar => _varNavBarBuscar;
  set varNavBarBuscar(String value) {
    _varNavBarBuscar = value;
  }

  bool _varVerNota = true;
  bool get varVerNota => _varVerNota;
  set varVerNota(bool value) {
    _varVerNota = value;
    prefs.setBool('ff_varVerNota', value);
  }

  String _varNome = '';
  String get varNome => _varNome;
  set varNome(String value) {
    _varNome = value;
    prefs.setString('ff_varNome', value);
  }

  String _varEmail = '';
  String get varEmail => _varEmail;
  set varEmail(String value) {
    _varEmail = value;
    prefs.setString('ff_varEmail', value);
  }

  bool _varPerfilIncompleto = true;
  bool get varPerfilIncompleto => _varPerfilIncompleto;
  set varPerfilIncompleto(bool value) {
    _varPerfilIncompleto = value;
    prefs.setBool('ff_varPerfilIncompleto', value);
  }

  DateTime? _varTempPassTime =
      DateTime.fromMillisecondsSinceEpoch(1761859440000);
  DateTime? get varTempPassTime => _varTempPassTime;
  set varTempPassTime(DateTime? value) {
    _varTempPassTime = value;
  }

  bool _varCheckConfirmation = false;
  bool get varCheckConfirmation => _varCheckConfirmation;
  set varCheckConfirmation(bool value) {
    _varCheckConfirmation = value;
  }

  bool _varLogginSecao = false;
  bool get varLogginSecao => _varLogginSecao;
  set varLogginSecao(bool value) {
    _varLogginSecao = value;
    prefs.setBool('ff_varLogginSecao', value);
  }

  DTnumerresendconfirmemailStruct _vrresendconfirm =
      DTnumerresendconfirmemailStruct.fromSerializableMap(jsonDecode(
          '{\"attempts\":\"0\",\"lockedUntil\":\"0\",\"buttonLocked\":\"false\",\"textFieldVisible\":\"false\"}'));
  DTnumerresendconfirmemailStruct get vrresendconfirm => _vrresendconfirm;
  set vrresendconfirm(DTnumerresendconfirmemailStruct value) {
    _vrresendconfirm = value;
    prefs.setString('ff_vrresendconfirm', value.serialize());
  }

  void updateVrresendconfirmStruct(
      Function(DTnumerresendconfirmemailStruct) updateFn) {
    updateFn(_vrresendconfirm);
    prefs.setString('ff_vrresendconfirm', _vrresendconfirm.serialize());
  }

  bool _vrRemovePhoto = false;
  bool get vrRemovePhoto => _vrRemovePhoto;
  set vrRemovePhoto(bool value) {
    _vrRemovePhoto = value;
  }

  bool _Internet = false;
  bool get Internet => _Internet;
  set Internet(bool value) {
    _Internet = value;
  }

  bool _internetCheckerStarted = false;
  bool get internetCheckerStarted => _internetCheckerStarted;
  set internetCheckerStarted(bool value) {
    _internetCheckerStarted = value;
  }

  /// Conjunto de informaçoes que guarda o retorno da API de consulta a CNPJ
  AgencyDraftStruct _agencyDraft =
      AgencyDraftStruct.fromSerializableMap(jsonDecode('{}'));
  AgencyDraftStruct get agencyDraft => _agencyDraft;
  set agencyDraft(AgencyDraftStruct value) {
    _agencyDraft = value;
  }

  void updateAgencyDraftStruct(Function(AgencyDraftStruct) updateFn) {
    updateFn(_agencyDraft);
  }

  bool _varCNPJVALID = false;
  bool get varCNPJVALID => _varCNPJVALID;
  set varCNPJVALID(bool value) {
    _varCNPJVALID = value;
  }

  Situacaocadastral? _varSituacaoCadastraENUNS = Situacaocadastral.unknown;
  Situacaocadastral? get varSituacaoCadastraENUNS => _varSituacaoCadastraENUNS;
  set varSituacaoCadastraENUNS(Situacaocadastral? value) {
    _varSituacaoCadastraENUNS = value;
  }

  /// variavel responsavel por armazenar o estado de cada usuario, essa recebe
  /// os valores da view_flow_state e armazena o estado a cada entrada no
  /// aplicativo
  FlowStateStruct _varSTATEFLOW = FlowStateStruct();
  FlowStateStruct get varSTATEFLOW => _varSTATEFLOW;
  set varSTATEFLOW(FlowStateStruct value) {
    _varSTATEFLOW = value;
  }

  void updateVarSTATEFLOWStruct(Function(FlowStateStruct) updateFn) {
    updateFn(_varSTATEFLOW);
  }

  /// variavel responsavel por determinar o tamanho maximo do nome de qualquer
  /// arquivo ou foto para exibição no front
  int _fileNameMaxLength = 40;
  int get fileNameMaxLength => _fileNameMaxLength;
  set fileNameMaxLength(int value) {
    _fileNameMaxLength = value;
  }

  /// Variavel responsavel pela vizualização unica da pagina statusagency quando
  /// a agencia for aprovada
  bool _agencyaprovvedconfig = false;
  bool get agencyaprovvedconfig => _agencyaprovvedconfig;
  set agencyaprovvedconfig(bool value) {
    _agencyaprovvedconfig = value;
    prefs.setBool('ff_agencyaprovvedconfig', value);
  }

  /// APPstate responsavel pelo datatype AgencySession que garante a
  /// persistencia dos dados da agência do usuario
  DTAgencyfieldsStruct _AgencySessionFIELDS = DTAgencyfieldsStruct();
  DTAgencyfieldsStruct get AgencySessionFIELDS => _AgencySessionFIELDS;
  set AgencySessionFIELDS(DTAgencyfieldsStruct value) {
    _AgencySessionFIELDS = value;
  }

  void updateAgencySessionFIELDSStruct(
      Function(DTAgencyfieldsStruct) updateFn) {
    updateFn(_AgencySessionFIELDS);
  }

  RegionDraftStruct _regionDraft = RegionDraftStruct();
  RegionDraftStruct get regionDraft => _regionDraft;
  set regionDraft(RegionDraftStruct value) {
    _regionDraft = value;
  }

  void updateRegionDraftStruct(Function(RegionDraftStruct) updateFn) {
    updateFn(_regionDraft);
  }

  List<DtAPIREDESStruct> _varDTREDESAPI = [];
  List<DtAPIREDESStruct> get varDTREDESAPI => _varDTREDESAPI;
  set varDTREDESAPI(List<DtAPIREDESStruct> value) {
    _varDTREDESAPI = value;
  }

  void addToVarDTREDESAPI(DtAPIREDESStruct value) {
    varDTREDESAPI.add(value);
  }

  void removeFromVarDTREDESAPI(DtAPIREDESStruct value) {
    varDTREDESAPI.remove(value);
  }

  void removeAtIndexFromVarDTREDESAPI(int index) {
    varDTREDESAPI.removeAt(index);
  }

  void updateVarDTREDESAPIAtIndex(
    int index,
    DtAPIREDESStruct Function(DtAPIREDESStruct) updateFn,
  ) {
    varDTREDESAPI[index] = updateFn(_varDTREDESAPI[index]);
  }

  void insertAtIndexInVarDTREDESAPI(int index, DtAPIREDESStruct value) {
    varDTREDESAPI.insert(index, value);
  }

  /// VARIAVEL GLOBAL RESPONSAVEL PELO CONTROLE DO CAMPO OBRIGATÓRIO EM TODOS
  /// DROPDOWN DA PAGINA DE CRIAÇÃO DE PDV
  bool _varDROPDOWNPDVFORM = false;
  bool get varDROPDOWNPDVFORM => _varDROPDOWNPDVFORM;
  set varDROPDOWNPDVFORM(bool value) {
    _varDROPDOWNPDVFORM = value;
  }

  /// VARIAVEL RESPONSAVEL PELO CONTROLE DE CHACE DO DROPDOWN REDES NO CADASTRO
  /// PDV, QUANDO TRUE O DROPDOWN IGNORA O CACHE E REFAZ A QUERY
  bool _varFORCENETWORKINGCACHE = true;
  bool get varFORCENETWORKINGCACHE => _varFORCENETWORKINGCACHE;
  set varFORCENETWORKINGCACHE(bool value) {
    _varFORCENETWORKINGCACHE = value;
  }

  /// Use App State (variável global)
  ///
  /// Porque:
  ///
  /// Você pode acessar de qualquer página
  ///
  /// Pode usar em filtros de RPC
  ///
  /// Pode usar em visibilidade condicional
  ///
  /// Pode usar em Infinity Scroll
  String _selectedNetworkId = '';
  String get selectedNetworkId => _selectedNetworkId;
  set selectedNetworkId(String value) {
    _selectedNetworkId = value;
  }

  DtFILTERSPDVSStruct _appFilterPDVs = DtFILTERSPDVSStruct();
  DtFILTERSPDVSStruct get appFilterPDVs => _appFilterPDVs;
  set appFilterPDVs(DtFILTERSPDVSStruct value) {
    _appFilterPDVs = value;
    prefs.setString('ff_appFilterPDVs', value.serialize());
  }

  void updateAppFilterPDVsStruct(Function(DtFILTERSPDVSStruct) updateFn) {
    updateFn(_appFilterPDVs);
    prefs.setString('ff_appFilterPDVs', _appFilterPDVs.serialize());
  }

  String _selectedNetworkChannel = '';
  String get selectedNetworkChannel => _selectedNetworkChannel;
  set selectedNetworkChannel(String value) {
    _selectedNetworkChannel = value;
  }
}

void _safeInit(Function() initializeField) {
  try {
    initializeField();
  } catch (_) {}
}

Future _safeInitAsync(Function() initializeField) async {
  try {
    await initializeField();
  } catch (_) {}
}
