import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/date_time_input.dart';
import 'package:flutter/material.dart';
import 'package:therapii/auth/firebase_auth_manager.dart';
import 'package:therapii/pages/journal_admin_analytics_page.dart';
import 'package:therapii/pages/journal_admin_content_feed_page.dart';
import 'package:therapii/pages/journal_admin_dashboard_page.dart';
import 'package:therapii/pages/journal_admin_patients_hub_page.dart';
import 'package:therapii/pages/journal_admin_settings_page.dart';
import 'package:therapii/pages/journal_admin_team_hub_page.dart';
import 'package:therapii/services/app_page_state_service.dart';
import 'package:therapii/utils/admin_access.dart';
import 'package:therapii/widgets/journal_admin_sidebar.dart';
import 'package:therapii/widgets/markdown_text_editing_controller.dart';

class JournalAdminStudioPage extends StatefulWidget {
  const JournalAdminStudioPage({super.key});

  @override
  State<JournalAdminStudioPage> createState() => _JournalAdminStudioPageState();
}

enum _LibraryFilter { all, drafts, published }

class _JournalAdminStudioPageState extends State<JournalAdminStudioPage> {
  static const _journalContentDoc = 'journal_content';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode();
  final List<TextEditingController> _blockControllers = [];
  final List<FocusNode> _blockFocusNodes = [];
  final TextEditingController _summaryController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  
  TextEditingController? _lastActiveController;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _articlesSubscription;
  bool _publishImmediately = false;
  bool _isPublic = true;
  bool _hasUnsavedChanges = false;
  bool _isContentLibraryCollapsed = true;
  bool _isLoadingArticles = true;
  bool _isSaving = false;
  bool _isApplyingArticle = false;
  bool _hasSeededInitialArticles = false;
  DateTime? _lastSavedAt;
  List<String> _tags = const [];
  List<_StudioArticle> _articles = const [];
  String? _selectedArticleId;
  _LibraryFilter _activeFilter = _LibraryFilter.all;

  @override
  void initState() {
    super.initState();
    _attachDirtyListeners();
    _searchController.addListener(() {
      if (mounted) setState(() {});
    });
    _subscribeToArticles();
  }

  void _onFocusChange() {
    if (_titleFocusNode.hasFocus) {
      _lastActiveController = _titleController;
    } else {
      for (int i = 0; i < _blockFocusNodes.length; i++) {
        if (_blockFocusNodes[i].hasFocus) {
          _lastActiveController = _blockControllers[i];
          break;
        }
      }
    }
  }

  void _attachDirtyListeners() {
    final controllers = [
      _titleController,
      ..._blockControllers,
      _summaryController,
      _dateController,
      _timeController,
    ];
    for (final controller in controllers) {
      controller.removeListener(_markDirty);
      controller.addListener(_markDirty);
    }
    
    _titleFocusNode.removeListener(_onFocusChange);
    _titleFocusNode.addListener(_onFocusChange);
    for (final node in _blockFocusNodes) {
      node.removeListener(_onFocusChange);
      node.addListener(_onFocusChange);
    }
  }

  void _markDirty() {
    if (_isApplyingArticle) return;
    if (!mounted) return;
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
  }

  CollectionReference<Map<String, dynamic>> get _articlesCollection =>
      _firestore
          .collection('admin_settings')
          .doc(_journalContentDoc)
          .collection('articles');

  Future<void> _subscribeToArticles() async {
    await _articlesSubscription?.cancel();
    _articlesSubscription = _articlesCollection
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .listen((snapshot) async {
      final defaultTitles = {
        'Building Resilience in Daily Life',
        '5 Steps to Better Sleep Hygiene',
        'Understanding CBT Core Principles',
        'Managing Workplace Anxiety'
      };

      final toDelete = snapshot.docs.where((d) {
        final data = d.data();
        return defaultTitles.contains(data['title']);
      }).toList();

      if (toDelete.isNotEmpty) {
        final batch = _firestore.batch();
        for (final d in toDelete) {
          batch.delete(d.reference);
        }
        await batch.commit();
        return;
      }

      final articles =
          snapshot.docs.map(_StudioArticle.fromDoc).toList(growable: false);
      final prevSelectedId = _selectedArticleId;
      final selectedId = _resolveSelectedArticleId(articles);
      final idChanged = prevSelectedId != selectedId;
      final isFirstLoad = _articles.isEmpty;

      if (!mounted) return;
      setState(() {
        _articles = articles;
        _selectedArticleId = selectedId;
        _isLoadingArticles = false;
      });

      if (isFirstLoad || idChanged) {
        final selectedArticle = _selectedArticle;
        if (selectedArticle != null) {
          _applyArticleToEditor(selectedArticle);
        } else if (_selectedArticleId == null) {
          _clearEditor();
        }
      }
    }, onError: (error) {
      if (!mounted) return;
      setState(() => _isLoadingArticles = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load content library: $error')),
      );
    });
  }

  String? _resolveSelectedArticleId(List<_StudioArticle> articles) {
    if (articles.isEmpty) return null;
    if (_selectedArticleId != null &&
        articles.any((article) => article.id == _selectedArticleId)) {
      return _selectedArticleId;
    }
    return articles.first.id;
  }


  _StudioArticle? get _selectedArticle {
    final selectedId = _selectedArticleId;
    if (selectedId == null) return null;
    for (final article in _articles) {
      if (article.id == selectedId) return article;
    }
    return null;
  }

  void _applyArticleToEditor(_StudioArticle article) {
    _isApplyingArticle = true;
    _lastActiveController = null;
    _titleController.text = article.title;
    
    for (int i = 0; i < _blockControllers.length; i++) {
      _blockControllers[i].dispose();
      _blockFocusNodes[i].dispose();
    }
    _blockControllers.clear();
    _blockFocusNodes.clear();
    
    if (article.blocks.isNotEmpty) {
      for (final blockText in article.blocks) {
        _blockControllers.add(MarkdownTextEditingController(text: blockText));
        _blockFocusNodes.add(FocusNode());
      }
    } else {
      _blockControllers.add(MarkdownTextEditingController());
      _blockFocusNodes.add(FocusNode());
    }
    
    _summaryController.text = article.summary;
    _dateController.text = article.date;
    _timeController.text = article.time;
    _publishImmediately = article.publishImmediately;
    _isPublic = article.isPublic;
    _tags = article.tags;
    _lastSavedAt = article.updatedAt;
    _hasUnsavedChanges = false;
    _isApplyingArticle = false;
    
    _attachDirtyListeners();
    if (mounted) setState(() {});
  }

  void _clearEditor() {
    _isApplyingArticle = true;
    _lastActiveController = null;
    _titleController.text = 'Untitled article';
    for (var c in _blockControllers) { c.dispose(); }
    for (var f in _blockFocusNodes) { f.dispose(); }
    _blockControllers.clear();
    _blockFocusNodes.clear();
    _blockControllers.add(MarkdownTextEditingController());
    _blockFocusNodes.add(FocusNode());
    _attachDirtyListeners();
    _summaryController.clear();
    _dateController.clear();
    _timeController.clear();
    _publishImmediately = false;
    _isPublic = true;
    _tags = const [];
    _lastSavedAt = null;
    _hasUnsavedChanges = false;
    _isApplyingArticle = false;
    if (mounted) setState(() {});
  }

  Future<void> _saveDraft({bool publish = false}) async {
    final articleId = _selectedArticleId;
    if (articleId == null) return;

    setState(() => _isSaving = true);
    final user = FirebaseAuthManager().currentUser;
    final now = DateTime.now();
    final status = publish
        ? (_publishImmediately ||
                (_dateController.text.trim().isEmpty &&
                    _timeController.text.trim().isEmpty)
            ? 'published'
            : 'scheduled')
        : 'draft';

    final payload = <String, dynamic>{
      'title': _titleController.text.trim(),
      'blocks': _blockControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList(growable: false),
      'summary': _summaryController.text.trim(),
      'date': _publishImmediately ? '' : _dateController.text.trim(),
      'time': _publishImmediately ? '' : _timeController.text.trim(),
      'publishImmediately': _publishImmediately,
      'isPublic': _isPublic,
      'tags': _tags,
      'status': status,
      'authorName': _authorNameFromUser(user),
      'authorId': user?.uid,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': _selectedArticle?.createdAt != null
          ? Timestamp.fromDate(_selectedArticle!.createdAt!)
          : FieldValue.serverTimestamp(),
    };

    try {
      await _articlesCollection
          .doc(articleId)
          .set(payload, SetOptions(merge: true));
      if (!mounted) return;
      setState(() {
        _lastSavedAt = now;
        _hasUnsavedChanges = false;
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(publish
                ? (status == 'published'
                    ? 'Article published to the feed.'
                    : 'Article saved and scheduled for publishing.')
                : 'Draft saved.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save article: $error')),
      );
    }
  }

  void _toggleVisibility(bool isPublic) {
    setState(() {
      _isPublic = isPublic;
      _hasUnsavedChanges = true;
    });
  }

  void _togglePublishImmediately(bool value) {
    setState(() {
      _publishImmediately = value;
      _hasUnsavedChanges = true;
    });
  }

  void _removeTag(String tag) {
    setState(() {
      _tags = _tags.where((t) => t != tag).toList(growable: false);
      _hasUnsavedChanges = true;
    });
  }

  void _addTag() {
    final base = 'New Tag';
    var next = base;
    var i = 1;
    while (_tags.contains(next)) {
      i += 1;
      next = '$base $i';
    }
    setState(() {
      _tags = [..._tags, next];
      _hasUnsavedChanges = true;
    });
  }

  void _toggleContentLibrary() {
    setState(() {
      _isContentLibraryCollapsed = !_isContentLibraryCollapsed;
    });
  }

  Future<void> _createArticle() async {
    final user = FirebaseAuthManager().currentUser;
    final ref = _articlesCollection.doc();
    final now = DateTime.now();
    await ref.set({
      'title': 'Untitled article',
      'blocks': const <String>[],
      'summary': '',
      'date': '',
      'time': '',
      'publishImmediately': false,
      'isPublic': true,
      'tags': const <String>[],
      'status': 'draft',
      'authorName': _authorNameFromUser(user),
      'authorId': user?.uid,
      'updatedAt': Timestamp.fromDate(now),
      'createdAt': Timestamp.fromDate(now),
    });

    if (!mounted) return;
    setState(() {
      _selectedArticleId = ref.id;
      _hasUnsavedChanges = false;
    });
  }

  void _selectArticle(String articleId) {
    _StudioArticle? article;
    for (final candidate in _articles) {
      if (candidate.id == articleId) {
        article = candidate;
        break;
      }
    }
    if (article == null) return;
    setState(() {
      _selectedArticleId = articleId;
    });
    _applyArticleToEditor(article);
  }

  Future<void> _deleteArticle(String articleId) async {
    _StudioArticle? article;
    for (final candidate in _articles) {
      if (candidate.id == articleId) {
        article = candidate;
        break;
      }
    }
    if (article == null) return;
    final targetArticle = article;

    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Delete article?'),
            content: Text(
              'Delete "${targetArticle.title}" from the content library? This cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldDelete) return;

    try {
      await _articlesCollection.doc(articleId).delete();
      if (!mounted) return;
      if (_selectedArticleId == articleId) {
        setState(() {
          _selectedArticleId = null;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted "${targetArticle.title}".')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete article: $error')),
      );
    }
  }

  String _authorNameFromUser(dynamic user) {
    final displayName = user?.displayName?.trim();
    if (displayName is String && displayName.isNotEmpty) return displayName;
    final email = user?.email?.trim();
    if (email is String && email.contains('@')) {
      return email.split('@').first;
    }
    return 'Admin';
  }

  List<_StudioArticle> get _visibleArticles {
    final query = _searchController.text.trim().toLowerCase();
    final filteredByStatus = _articles.where((article) {
      switch (_activeFilter) {
        case _LibraryFilter.all:
          return true;
        case _LibraryFilter.drafts:
          return article.status == 'draft';
        case _LibraryFilter.published:
          return article.status == 'published' || article.status == 'scheduled';
      }
    });

    return filteredByStatus.where((article) {
      if (query.isEmpty) return true;
      return article.title.toLowerCase().contains(query) ||
          article.summary.toLowerCase().contains(query) ||
          article.blocks.any((b) => b.toLowerCase().contains(query)) ||
          article.authorName.toLowerCase().contains(query);
    }).toList(growable: false);
  }

  void _onSidebarNavigate(JournalAdminSidebarItem item) {
    switch (item) {
      case JournalAdminSidebarItem.dashboard:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const JournalAdminDashboardPage()),
        );
        break;
      case JournalAdminSidebarItem.articles:
        return;
      case JournalAdminSidebarItem.contentFeed:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
              builder: (_) => const JournalAdminContentFeedPage()),
        );
        break;
      case JournalAdminSidebarItem.team:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const JournalAdminTeamHubPage()),
        );
        break;
      case JournalAdminSidebarItem.patients:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
              builder: (_) => const JournalAdminPatientsHubPage()),
        );
        break;
      case JournalAdminSidebarItem.analytics:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const JournalAdminAnalyticsPage()),
        );
        break;
      case JournalAdminSidebarItem.settings:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const JournalAdminSettingsPage()),
        );
        break;
    }
  }

  String get _saveStatusText {
    if (_isSaving) return 'Saving...';
    if (_hasUnsavedChanges) return 'Unsaved changes';
    final savedAt = _lastSavedAt;
    if (savedAt == null) return 'Not saved yet';
    final hh = savedAt.hour.toString().padLeft(2, '0');
    final mm = savedAt.minute.toString().padLeft(2, '0');
    return 'Saved at $hh:$mm';
  }

  @override
  void dispose() {
    _articlesSubscription?.cancel();
    _searchController.dispose();
    _titleController.dispose();
    _titleFocusNode.dispose();
    for (int i = 0; i < _blockControllers.length; i++) {
      _blockControllers[i].dispose();
      _blockFocusNodes[i].dispose();
    }
    _summaryController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  void _onToolbarAction(String action) {
    TextEditingController? activeController = _lastActiveController;
    
    if (activeController == null) {
      if (_blockControllers.isNotEmpty) {
        activeController = _blockControllers.last;
      } else if (_titleController.text.isNotEmpty) {
        activeController = _titleController;
      } else {
        return;
      }
    }
    
    final selection = activeController.selection;
    final text = activeController.text;
    
    String newText;
    TextSelection newSelection;
    
    if (selection.isValid && selection.start >= 0 && selection.end >= 0) {
      final start = selection.start;
      final end = selection.end;
      final selectedText = text.substring(start, end);
      final before = text.substring(0, start);
      final after = text.substring(end);
      
      switch (action) {
        case 'bold':
          newText = '$before**$selectedText**$after';
          newSelection = TextSelection(baseOffset: start + 2, extentOffset: start + 2 + selectedText.length);
          if (selectedText.isEmpty) newSelection = TextSelection.collapsed(offset: start + 2);
          break;
        case 'italic':
          newText = '$before*$selectedText*$after';
          newSelection = TextSelection(baseOffset: start + 1, extentOffset: start + 1 + selectedText.length);
          if (selectedText.isEmpty) newSelection = TextSelection.collapsed(offset: start + 1);
          break;
        case 'link':
          newText = '$before[$selectedText](url)$after';
          newSelection = TextSelection(baseOffset: start + 1 + selectedText.length + 2, extentOffset: start + 1 + selectedText.length + 5);
          break;
        case 'title':
          newText = '$before# $selectedText$after';
          newSelection = TextSelection.collapsed(offset: start + 2 + selectedText.length);
          break;
        case 'quote':
          newText = '$before> $selectedText$after';
          newSelection = TextSelection.collapsed(offset: start + 2 + selectedText.length);
          break;
        case 'list':
          newText = '$before- $selectedText$after';
          newSelection = TextSelection.collapsed(offset: start + 2 + selectedText.length);
          break;
        case 'image':
          newText = '$before![alt text](image_url)$after';
          newSelection = TextSelection(baseOffset: start + 14, extentOffset: start + 23);
          break;
        default:
          return;
      }
    } else {
      final before = text;
      switch (action) {
        case 'bold':
          newText = '$before****';
          newSelection = TextSelection.collapsed(offset: before.length + 2);
          break;
        case 'italic':
          newText = '$before**';
          newSelection = TextSelection.collapsed(offset: before.length + 1);
          break;
        case 'link':
          newText = '$before[](url)';
          newSelection = TextSelection.collapsed(offset: before.length + 1);
          break;
        case 'title':
          newText = '$before\n# ';
          newSelection = TextSelection.collapsed(offset: before.length + 3);
          break;
        case 'quote':
          newText = '$before\n> ';
          newSelection = TextSelection.collapsed(offset: before.length + 3);
          break;
        case 'list':
          newText = '$before\n- ';
          newSelection = TextSelection.collapsed(offset: before.length + 3);
          break;
        case 'image':
          newText = '$before\n![alt text](image_url)';
          newSelection = TextSelection.collapsed(offset: before.length + 14);
          break;
        default:
          return;
      }
    }
    
    activeController.value = TextEditingValue(
      text: newText,
      selection: newSelection,
    );

    // Re-focus
    if (activeController == _titleController) {
      _titleFocusNode.requestFocus();
    } else {
      final idx = _blockControllers.indexOf(activeController);
      if (idx != -1) {
        _blockFocusNodes[idx].requestFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final canShowLibrary = width >= 1100;
    final showRightRail = width >= 1380;
    final selectedArticle = _selectedArticle;

    return RememberAppPage(
      pageId: AppPageId.journalAdminStudio,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F7F8),
        body: SafeArea(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              JournalAdminSidebar(
                activeItem: JournalAdminSidebarItem.articles,
                onNavigate: _onSidebarNavigate,
              ),
              if (canShowLibrary)
                _ContentLibrary(
                  isCollapsed: _isContentLibraryCollapsed,
                  onToggleCollapse: _toggleContentLibrary,
                  searchController: _searchController,
                  activeFilter: _activeFilter,
                  onFilterChanged: (filter) {
                    setState(() => _activeFilter = filter);
                  },
                  onCreateArticle: _createArticle,
                  articles: _visibleArticles,
                  selectedArticleId: _selectedArticleId,
                  onSelectArticle: _selectArticle,
                  onDeleteArticle: _deleteArticle,
                  isLoading: _isLoadingArticles,
                ),
              Expanded(
                child: _EditorPanel(
                  saveStatusText: _saveStatusText,
                  articleTitle: selectedArticle?.title ?? 'Untitled article',
                  titleController: _titleController,
                  titleFocusNode: _titleFocusNode,
                  blockControllers: _blockControllers,
                  blockFocusNodes: _blockFocusNodes,
                  onAddBlock: () {
                    setState(() {
                      _blockControllers.add(MarkdownTextEditingController());
                      _blockFocusNodes.add(FocusNode());
                      _attachDirtyListeners();
                    });
                  },
                  onRemoveBlock: (index) {
                    setState(() {
                      if (_lastActiveController == _blockControllers[index]) {
                        _lastActiveController = null;
                      }
                      _blockControllers[index].dispose();
                      _blockControllers.removeAt(index);
                      _blockFocusNodes[index].dispose();
                      _blockFocusNodes.removeAt(index);
                      _hasUnsavedChanges = true;
                    });
                  },
                  onToolbarAction: _onToolbarAction,
                  isLoading: _isLoadingArticles,
                ),
              ),
              if (showRightRail)
                _PublishingRail(
                  tags: _tags,
                  summaryController: _summaryController,
                  publishImmediately: _publishImmediately,
                  onPublishImmediatelyChanged: _togglePublishImmediately,
                  dateController: _dateController,
                  timeController: _timeController,
                  isPublic: _isPublic,
                  onVisibilityChanged: _toggleVisibility,
                  onDeleteTag: _removeTag,
                  onAddTag: _addTag,
                  onPublish: () => _saveDraft(publish: true),
                  onSaveDraft: () => _saveDraft(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _handleToolbarAction {
}

class _removeBlock {
}

class _addBlock {
}

class _continueController {
}

class _bulletsController {
}

class _sectionBodyController {
}

class _sectionTitleController {
}

class _introController {
}

class _quoteController {
}

class _LeftSidebar extends StatelessWidget {
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;

  const _LeftSidebar({
    required this.isCollapsed,
    required this.onToggleCollapse,
  });

  String _displayName() {
    final user = FirebaseAuthManager().currentUser;
    final displayName = user?.displayName?.trim() ?? '';
    if (displayName.isNotEmpty) return displayName;
    final email = user?.email ?? '';
    final local = email.contains('@') ? email.split('@').first : email;
    return local.isNotEmpty ? local : 'Guest';
  }

  String _initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.characters.first.toUpperCase();
    }
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  String? _safePhotoUrl() {
    final raw = FirebaseAuthManager().currentUser?.photoURL?.trim();
    if (raw == null || raw.isEmpty) return null;
    final uri = Uri.tryParse(raw);
    if (uri == null) return null;
    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') return null;
    return raw;
  }

  bool _isAdmin() {
    return AdminAccess.isAdminEmail(FirebaseAuthManager().currentUser?.email);
  }

  @override
  Widget build(BuildContext context) {
    final name = _displayName();
    final photoUrl = _safePhotoUrl();
    final hasPhoto = photoUrl != null;
    final isAdmin = _isAdmin();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      width: isCollapsed ? 96 : 260,
      decoration: const BoxDecoration(
        color: Color(0xFFFDFDFD),
        border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
                isCollapsed ? 12 : 24, 24, isCollapsed ? 12 : 16, 8),
            child: Row(
              children: [
                const _LogoGlyph(),
                if (!isCollapsed) ...[
                  const SizedBox(width: 10),
                  const Flexible(
                    child: Text(
                      'Therapii',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                const Spacer(),
                IconButton(
                  tooltip: isCollapsed ? 'Expand sidebar' : 'Collapse sidebar',
                  onPressed: onToggleCollapse,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 30, minHeight: 30),
                  icon: Icon(
                    isCollapsed
                        ? Icons.chevron_right_rounded
                        : Icons.chevron_left_rounded,
                    size: 20,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 10 : 16),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  _SidebarGroup(
                    title: 'Main',
                    collapsed: isCollapsed,
                    items: [
                      _NavItemData(
                        icon: Icons.dashboard_outlined,
                        label: 'Dashboard',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) =>
                                    const JournalAdminDashboardPage()),
                          );
                        },
                      ),
                      const _NavItemData(
                          icon: Icons.article_outlined,
                          label: 'Articles',
                          active: true),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SidebarGroup(
                    title: 'People',
                    collapsed: isCollapsed,
                    items: [
                      _NavItemData(
                        icon: Icons.group_outlined,
                        label: 'Team',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) =>
                                    const JournalAdminTeamHubPage()),
                          );
                        },
                      ),
                      _NavItemData(
                        icon: Icons.people_alt_outlined,
                        label: 'Clients',
                        onTap: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                                builder: (_) =>
                                    const JournalAdminPatientsHubPage()),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SidebarGroup(
                    title: 'System',
                    collapsed: isCollapsed,
                    items: [
                      _NavItemData(
                        icon: Icons.analytics_outlined,
                        label: 'Analytics',
                        onTap: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                                builder: (_) =>
                                    const JournalAdminAnalyticsPage()),
                          );
                        },
                      ),
                      _NavItemData(
                        icon: Icons.settings_outlined,
                        label: 'Settings',
                        onTap: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                                builder: (_) =>
                                    const JournalAdminSettingsPage()),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFFAFAFA),
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: isCollapsed
                ? Column(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFFE2E8F0),
                        backgroundImage:
                            hasPhoto ? NetworkImage(photoUrl) : null,
                        onBackgroundImageError: hasPhoto ? (_, __) {} : null,
                        child: hasPhoto
                            ? null
                            : Text(
                                _initials(name),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF475569)),
                              ),
                      ),
                      const SizedBox(height: 8),
                      IconButton(
                        tooltip: 'Logout',
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 32, minHeight: 32),
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.logout,
                            color: Color(0xFF64748B), size: 20),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFFE2E8F0),
                        backgroundImage:
                            hasPhoto ? NetworkImage(photoUrl) : null,
                        onBackgroundImageError: hasPhoto ? (_, __) {} : null,
                        child: hasPhoto
                            ? null
                            : Text(
                                _initials(name),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF475569)),
                              ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w700),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Text(
                                  'View Profile',
                                  style: TextStyle(
                                      fontSize: 11, color: Color(0xFF64748B)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (isAdmin) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2B8CEE)
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                          color: const Color(0xFF2B8CEE)
                                              .withValues(alpha: 0.3)),
                                    ),
                                    child: const Text(
                                      'ADMIN',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.4,
                                        color: Color(0xFF2B8CEE),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Logout',
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 32, minHeight: 32),
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.logout,
                            color: Color(0xFF64748B), size: 20),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _LogoGlyph extends StatelessWidget {
  const _LogoGlyph();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFF2B8CEE).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(6),
      child: Image.asset(
        'assets/images/therapii_logo_blue.png',
        fit: BoxFit.contain,
      ),
    );
  }
}

class _SidebarGroup extends StatelessWidget {
  final String title;
  final List<_NavItemData> items;
  final bool collapsed;
  const _SidebarGroup({
    required this.title,
    required this.items,
    this.collapsed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          collapsed ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        if (!collapsed)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.7,
                color: Color(0xFF94A3B8),
              ),
            ),
          ),
        ...items.map((item) => _SidebarItem(item, collapsed: collapsed)),
      ],
    );
  }
}

class _NavItemData {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;
  const _NavItemData({
    required this.icon,
    required this.label,
    this.active = false,
    this.onTap,
  });
}

class _SidebarItem extends StatelessWidget {
  final _NavItemData item;
  final bool collapsed;
  const _SidebarItem(this.item, {this.collapsed = false});

  @override
  Widget build(BuildContext context) {
    final active = item.active;
    if (collapsed) {
      return Container(
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFEFF6FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Tooltip(
          message: item.label,
          child: InkWell(
            onTap: item.onTap,
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 48,
              height: 44,
              child: Icon(
                item.icon,
                size: 20,
                color:
                    active ? const Color(0xFF2B8CEE) : const Color(0xFF64748B),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFEFF6FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        onTap: item.onTap,
        dense: true,
        minVerticalPadding: 0,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Icon(
          item.icon,
          size: 20,
          color: active ? const Color(0xFF2B8CEE) : const Color(0xFF64748B),
        ),
        title: Text(
          item.label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? const Color(0xFF2B8CEE) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}

class _ContentLibrary extends StatelessWidget {
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;
  final TextEditingController searchController;
  final _LibraryFilter activeFilter;
  final ValueChanged<_LibraryFilter> onFilterChanged;
  final VoidCallback onCreateArticle;
  final List<_StudioArticle> articles;
  final String? selectedArticleId;
  final ValueChanged<String> onSelectArticle;
  final ValueChanged<String> onDeleteArticle;
  final bool isLoading;
  const _ContentLibrary({
    required this.isCollapsed,
    required this.onToggleCollapse,
    required this.searchController,
    required this.activeFilter,
    required this.onFilterChanged,
    required this.onCreateArticle,
    required this.articles,
    required this.selectedArticleId,
    required this.onSelectArticle,
    required this.onDeleteArticle,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      width: isCollapsed ? 68 : 340,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: isCollapsed
          ? Column(
              children: [
                const SizedBox(height: 12),
                IconButton(
                  tooltip: 'Expand content library',
                  onPressed: onToggleCollapse,
                  icon: const Icon(Icons.chevron_right_rounded,
                      color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 8),
                const Icon(Icons.menu_book_rounded,
                    color: Color(0xFF2B8CEE), size: 22),
                const SizedBox(height: 10),
                const RotatedBox(
                  quarterTurns: 3,
                  child: Text(
                    'Library',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Content Library',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w800),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Collapse content library',
                            onPressed: onToggleCollapse,
                            icon: const Icon(Icons.chevron_left_rounded,
                                color: Color(0xFF64748B)),
                          ),
                          IconButton(
                            onPressed: onCreateArticle,
                            icon:
                                const Icon(Icons.add, color: Color(0xFF2B8CEE)),
                          ),
                        ],
                      ),
                      TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          isDense: true,
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          hintText: 'Search articles...',
                          hintStyle: const TextStyle(fontSize: 13),
                          prefixIcon: const Icon(Icons.search, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _LibraryTab(
                            label: 'All',
                            active: activeFilter == _LibraryFilter.all,
                            onTap: () => onFilterChanged(_LibraryFilter.all),
                          ),
                          _LibraryTab(
                            label: 'Drafts',
                            active: activeFilter == _LibraryFilter.drafts,
                            onTap: () => onFilterChanged(_LibraryFilter.drafts),
                          ),
                          _LibraryTab(
                            label: 'Published',
                            active: activeFilter == _LibraryFilter.published,
                            onTap: () =>
                                onFilterChanged(_LibraryFilter.published),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : articles.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: Text(
                                  'No articles match the current filter.',
                                  style: TextStyle(color: Color(0xFF64748B)),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                              itemCount: articles.length,
                              itemBuilder: (context, index) {
                                final article = articles[index];
                                return _ArticleListItem(
                                  status: article.statusLabel,
                                  statusColor: article.statusColor,
                                  title: article.title,
                                  subtitle: article.librarySubtitle,
                                  author: article.authorName,
                                  age: article.relativeAgeLabel,
                                  highlighted: article.id == selectedArticleId,
                                  onTap: () => onSelectArticle(article.id),
                                  onDelete: () => onDeleteArticle(article.id),
                                );
                              },
                            ),
                ),
              ],
            ),
    );
  }
}

class _LibraryTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _LibraryTab(
      {required this.label, required this.onTap, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? const Color(0xFF111418) : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? const Color(0xFF111418) : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }
}

class _ArticleListItem extends StatelessWidget {
  final String status;
  final Color statusColor;
  final String title;
  final String subtitle;
  final String author;
  final String age;
  final bool highlighted;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ArticleListItem({
    required this.status,
    required this.statusColor,
    required this.title,
    required this.subtitle,
    required this.author,
    required this.age,
    required this.onTap,
    required this.onDelete,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: highlighted ? const Color(0xFFEEF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: highlighted
                  ? const Color(0xFFBFDBFE)
                  : const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: statusColor),
                  ),
                ),
                const Spacer(),
                Text(age,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF64748B))),
                PopupMenuButton<String>(
                  tooltip: 'Article actions',
                  onSelected: (value) {
                    if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded,
                              size: 18, color: Color(0xFFDC2626)),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                  icon: const Icon(
                    Icons.more_horiz_rounded,
                    size: 18,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(title,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const CircleAvatar(
                    radius: 9, backgroundColor: Color(0xFFE2E8F0)),
                const SizedBox(width: 6),
                Text(author,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF64748B))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EditorPanel extends StatelessWidget {
  final String saveStatusText;
  final String articleTitle;
  final TextEditingController titleController;
  final FocusNode titleFocusNode;
  final List<TextEditingController> blockControllers;
  final List<FocusNode> blockFocusNodes;
  final VoidCallback onAddBlock;
  final ValueChanged<int> onRemoveBlock;
  final ValueChanged<String> onToolbarAction;
  final bool isLoading;

  const _EditorPanel({
    required this.saveStatusText,
    required this.articleTitle,
    required this.titleController,
    required this.titleFocusNode,
    required this.blockControllers,
    required this.blockFocusNodes,
    required this.onAddBlock,
    required this.onRemoveBlock,
    required this.onToolbarAction,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.75),
            border: const Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Dashboard > Articles > Editing: $articleTitle',
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                saveStatusText,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.visibility_outlined, size: 18),
                label: const Text('Preview'),
              ),
            ],
          ),
        ),
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 820),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A2632),
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _ToolbarIcon(Icons.format_bold, tooltip: 'Bold', onPressed: () => onToolbarAction('bold')),
                                _ToolbarIcon(Icons.format_italic, tooltip: 'Italic', onPressed: () => onToolbarAction('italic')),
                                _ToolbarIcon(Icons.link, tooltip: 'Link', onPressed: () => onToolbarAction('link')),
                                const _ToolbarDivider(),
                                _ToolbarIcon(Icons.title, tooltip: 'Heading', onPressed: () => onToolbarAction('title')),
                                _ToolbarIcon(Icons.format_quote, tooltip: 'Quote', onPressed: () => onToolbarAction('quote')),
                                _ToolbarIcon(Icons.format_list_bulleted, tooltip: 'Bullet List', onPressed: () => onToolbarAction('list')),
                                const _ToolbarDivider(),
                                _ToolbarIcon(Icons.add_photo_alternate_outlined, tooltip: 'Image', onPressed: () => onToolbarAction('image')),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border:
                                  Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _EditorBlock(
                                  controller: titleController,
                                  focusNode: titleFocusNode,
                                  minLines: 1,
                                  maxLines: null,
                                  hintText: 'Article Title',
                                  style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w800, height: 1.1, color: Color(0xFF0F172A)),
                                ),
                                const SizedBox(height: 12),
                                ...blockControllers.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final controller = entry.value;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: _EditorBlock(
                                            controller: controller,
                                            focusNode: blockFocusNodes[index],
                                            minLines: 1,
                                            maxLines: null,
                                            hintText: "Continue writing or type '/' for commands",
                                            style: const TextStyle(fontSize: 18, height: 1.6, color: Color(0xFF334155)),
                                          ),
                                        ),
                                        if (blockControllers.length > 1)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 8, left: 8),
                                            child: IconButton(
                                              onPressed: () => onRemoveBlock(index),
                                              icon: const Icon(Icons.close, size: 16, color: Color(0xFFCBD5E1)),
                                              tooltip: 'Remove block',
                                              hoverColor: const Color(0xFFF1F5F9),
                                              splashRadius: 20,
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                }),
                                const SizedBox(height: 16),
                                Align(
                                  alignment: Alignment.center,
                                  child: TextButton.icon(
                                    onPressed: onAddBlock,
                                    icon: const Icon(Icons.add, size: 20),
                                    label: const Text('Add block', style: TextStyle(fontWeight: FontWeight.w700)),
                                    style: TextButton.styleFrom(
                                      foregroundColor: const Color(0xFF64748B),
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _ToolbarIcon extends StatelessWidget {
  final IconData icon;
  final String? tooltip;
  final VoidCallback onPressed;
  const _ToolbarIcon(this.icon, {this.tooltip, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 20, color: Colors.white),
      splashRadius: 18,
      hoverColor: Colors.white.withValues(alpha: 0.1),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _ToolbarDivider extends StatelessWidget {
  const _ToolbarDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 16,
      color: Colors.white24,
      margin: const EdgeInsets.symmetric(horizontal: 2),
    );
  }
}

class _EditorBlock extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final int minLines;
  final int? maxLines;
  final String hintText;
  final TextStyle style;

  const _EditorBlock({
    required this.controller,
    required this.focusNode,
    required this.minLines,
    this.maxLines,
    required this.hintText,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      minLines: minLines,
      maxLines: maxLines,
      decoration: InputDecoration(
        border: InputBorder.none,
        hintText: hintText,
        hintStyle: const TextStyle(color: Color(0xFFCBD5E1)),
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
      ),
      style: style,
    );
  }
}



class _PublishingRail extends StatelessWidget {
  final List<String> tags;
  final TextEditingController summaryController;
  final bool publishImmediately;
  final ValueChanged<bool> onPublishImmediatelyChanged;
  final TextEditingController dateController;
  final TextEditingController timeController;
  final bool isPublic;
  final ValueChanged<bool> onVisibilityChanged;
  final ValueChanged<String> onDeleteTag;
  final VoidCallback onAddTag;
  final Future<void> Function() onPublish;
  final Future<void> Function() onSaveDraft;
  const _PublishingRail({
    required this.tags,
    required this.summaryController,
    required this.publishImmediately,
    required this.onPublishImmediatelyChanged,
    required this.dateController,
    required this.timeController,
    required this.isPublic,
    required this.onVisibilityChanged,
    required this.onDeleteTag,
    required this.onAddTag,
    required this.onPublish,
    required this.onSaveDraft,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Publishing Intelligence',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 4),
                Text(
                  'Configure AI tags and scheduling.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _PanelTitle('AI Personalization Tags'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...tags.map((tag) => _TagChip(
                          label: tag, onRemove: () => onDeleteTag(tag))),
                      _AddChip(onTap: onAddTag),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const _PanelTitle('Summary / Meta Description'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: summaryController,
                    minLines: 4,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Enter a brief summary for search results...',
                      filled: true,
                      fillColor: Color(0xFFF8FAFC),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const _PanelTitle('Publishing Schedule'),
                  const SizedBox(height: 8),
                  _ScheduleCard(
                    publishImmediately: publishImmediately,
                    onPublishImmediatelyChanged: onPublishImmediatelyChanged,
                    dateController: dateController,
                    timeController: timeController,
                  ),
                  const SizedBox(height: 20),
                  const _PanelTitle('Visibility'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _VisibilityButton(
                          label: 'Public',
                          icon: Icons.public,
                          active: isPublic,
                          onTap: () => onVisibilityChanged(true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _VisibilityButton(
                          label: 'Private',
                          icon: Icons.lock_outline,
                          active: !isPublic,
                          onTap: () => onVisibilityChanged(false),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onPublish,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: const Color(0xFF2B8CEE),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.send, size: 18),
                    label: const Text('Publish Now',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onSaveDraft,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Save as Draft',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelTitle extends StatelessWidget {
  final String title;
  const _PanelTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _TagChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFDBEAFE),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1D4ED8))),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 14, color: Color(0xFF1D4ED8)),
          ),
        ],
      ),
    );
  }
}

class _AddChip extends StatelessWidget {
  final VoidCallback onTap;
  const _AddChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 14, color: Color(0xFF64748B)),
            SizedBox(width: 4),
            Text('Add Tag',
                style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final bool publishImmediately;
  final ValueChanged<bool> onPublishImmediatelyChanged;
  final TextEditingController dateController;
  final TextEditingController timeController;

  // Note: Input fields for date/time are now enhanced using the
  // DateTimeInput widget for a world-class experience.
  const _ScheduleCard({
    required this.publishImmediately,
    required this.onPublishImmediatelyChanged,
    required this.dateController,
    required this.timeController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Publish Immediately',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
              ),
              Switch(
                  value: publishImmediately,
                  onChanged: onPublishImmediatelyChanged),
            ],
          ),
          if (!publishImmediately) ...[
            const SizedBox(height: 8),
            DateTimeInput(
              label: 'Date',
              mode: DateTimeInputMode.date,
              initialValue: dateController.text,
              onChanged: (val) => dateController.text = val,
            ),
            const SizedBox(height: 8),
            DateTimeInput(
              label: 'Time',
              mode: DateTimeInputMode.time,
              initialValue: timeController.text,
              onChanged: (val) => timeController.text = val,
            ),
          ],
        ],
      ),
    );
  }
}

class _VisibilityButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _VisibilityButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFEFF6FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 16,
                color:
                    active ? const Color(0xFF2B8CEE) : const Color(0xFF64748B)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                  color: active
                      ? const Color(0xFF2B8CEE)
                      : const Color(0xFF64748B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudioArticle {
  final String id;
  final String title;
  final List<String> blocks;
  final String summary;
  final String date;
  final String time;
  final bool publishImmediately;
  final bool isPublic;
  final List<String> tags;
  final String status;
  final String authorName;
  final DateTime? updatedAt;
  final DateTime? createdAt;

  const _StudioArticle({
    required this.id,
    required this.title,
    required this.blocks,
    required this.summary,
    required this.date,
    required this.time,
    required this.publishImmediately,
    required this.isPublic,
    required this.tags,
    required this.status,
    required this.authorName,
    required this.updatedAt,
    required this.createdAt,
  });

  factory _StudioArticle.fromDoc(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final tags = data['tags'];
    
    List<String> blocks = [];
    if (data['blocks'] != null) {
      blocks = (data['blocks'] as List).whereType<String>().toList(growable: false);
    } else {
      // Legacy data support
      if ((data['quote'] as String?)?.isNotEmpty == true) blocks.add(data['quote'] as String);
      if ((data['intro'] as String?)?.isNotEmpty == true) blocks.add(data['intro'] as String);
      if ((data['sectionTitle'] as String?)?.isNotEmpty == true) blocks.add(data['sectionTitle'] as String);
      if ((data['sectionBody'] as String?)?.isNotEmpty == true) blocks.add(data['sectionBody'] as String);
      final bullets = data['bullets'];
      if (bullets is List) {
        final bulletsStr = bullets.whereType<String>().join('\n');
        if (bulletsStr.isNotEmpty) blocks.add(bulletsStr);
      }
      if ((data['continueText'] as String?)?.isNotEmpty == true) blocks.add(data['continueText'] as String);
    }

    return _StudioArticle(
      id: doc.id,
      title: (data['title'] as String?)?.trim().isNotEmpty == true ? data['title'] as String : 'Untitled article',
      blocks: blocks,
      summary: (data['summary'] as String?) ?? '',
      date: (data['date'] as String?) ?? '',
      time: (data['time'] as String?) ?? '',
      publishImmediately: data['publishImmediately'] as bool? ?? false,
      isPublic: data['isPublic'] as bool? ?? true,
      tags: tags is List
          ? tags.whereType<String>().toList(growable: false)
          : const [],
      status: (data['status'] as String?) ?? 'draft',
      authorName: (data['authorName'] as String?)?.trim().isNotEmpty == true
          ? data['authorName'] as String
          : 'Admin',
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  String get statusLabel {
    switch (status) {
      case 'published':
        return 'Published';
      case 'scheduled':
        return 'Scheduled';
      default:
        return 'Draft';
    }
  }

  Color get statusColor {
    switch (status) {
      case 'published':
        return const Color(0xFF10B981);
      case 'scheduled':
        return const Color(0xFF64748B);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  String get librarySubtitle {
    final source = summary.trim().isNotEmpty ? summary.trim() : (blocks.isNotEmpty ? blocks.first.trim() : '');
    if (source.isEmpty) return 'Start writing to see a live preview here...';
    return source;
  }

  String get relativeAgeLabel {
    if (status == 'scheduled' && date.trim().isNotEmpty) return date.trim();

    final updated = updatedAt;
    if (updated == null) return 'Just now';

    final diff = DateTime.now().difference(updated);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${updated.month}/${updated.day}/${updated.year}';
  }
}
