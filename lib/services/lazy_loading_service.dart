import 'dart:async';
import 'package:flutter/material.dart';

/// Generic lazy loading service for paginated data
class LazyLoadingService<T> {
  final Future<List<T>> Function(int page, int limit) _loadData;
  final int _pageSize;
  
  final List<T> _items = [];
  int _currentPage = 0;
  bool _isLoading = false;
  bool _hasMoreData = true;
  String? _errorMessage;
  
  final StreamController<LazyLoadingState<T>> _stateController = 
      StreamController<LazyLoadingState<T>>.broadcast();

  LazyLoadingService({
    required Future<List<T>> Function(int page, int limit) loadData,
    int pageSize = 20,
  }) : _loadData = loadData, _pageSize = pageSize;

  /// Stream of loading states
  Stream<LazyLoadingState<T>> get stateStream => _stateController.stream;

  /// Current items
  List<T> get items => List.unmodifiable(_items);

  /// Current loading state
  bool get isLoading => _isLoading;

  /// Whether more data is available
  bool get hasMoreData => _hasMoreData;

  /// Current error message
  String? get errorMessage => _errorMessage;

  /// Load initial data
  Future<void> loadInitial() async {
    if (_isLoading) return;

    _currentPage = 0;
    _hasMoreData = true;
    _items.clear();
    _errorMessage = null;

    await _loadPage();
  }

  /// Load next page
  Future<void> loadMore() async {
    if (_isLoading || !_hasMoreData) return;
    await _loadPage();
  }

  /// Refresh data
  Future<void> refresh() async {
    _currentPage = 0;
    _hasMoreData = true;
    _items.clear();
    _errorMessage = null;
    await _loadPage();
  }

  /// Load a specific page
  Future<void> _loadPage() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      _emitState();

      final newItems = await _loadData(_currentPage + 1, _pageSize);
      
      if (newItems.isEmpty) {
        _hasMoreData = false;
      } else {
        _items.addAll(newItems);
        _currentPage++;
        _hasMoreData = newItems.length >= _pageSize;
      }
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('LazyLoadingService error: $e');
    } finally {
      _isLoading = false;
      _emitState();
    }
  }

  /// Emit current state
  void _emitState() {
    _stateController.add(LazyLoadingState<T>(
      items: List.unmodifiable(_items),
      isLoading: _isLoading,
      hasMoreData: _hasMoreData,
      errorMessage: _errorMessage,
    ));
  }

  /// Add item to the beginning of the list
  void prependItem(T item) {
    _items.insert(0, item);
    _emitState();
  }

  /// Add item to the end of the list
  void appendItem(T item) {
    _items.add(item);
    _emitState();
  }

  /// Remove item from the list
  void removeItem(T item) {
    _items.remove(item);
    _emitState();
  }

  /// Update item in the list
  void updateItem(T oldItem, T newItem) {
    final index = _items.indexOf(oldItem);
    if (index != -1) {
      _items[index] = newItem;
      _emitState();
    }
  }

  /// Clear all data
  void clear() {
    _items.clear();
    _currentPage = 0;
    _hasMoreData = true;
    _errorMessage = null;
    _emitState();
  }

  /// Dispose resources
  void dispose() {
    _stateController.close();
  }
}

/// State class for lazy loading
class LazyLoadingState<T> {
  final List<T> items;
  final bool isLoading;
  final bool hasMoreData;
  final String? errorMessage;

  const LazyLoadingState({
    required this.items,
    required this.isLoading,
    required this.hasMoreData,
    this.errorMessage,
  });

  bool get isEmpty => items.isEmpty && !isLoading;
  bool get hasError => errorMessage != null;
}

/// Widget for lazy loading lists
class LazyLoadingListView<T> extends StatefulWidget {
  final LazyLoadingService<T> service;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  final Widget? emptyWidget;
  final EdgeInsets? padding;
  final ScrollController? controller;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const LazyLoadingListView({
    super.key,
    required this.service,
    required this.itemBuilder,
    this.loadingWidget,
    this.errorWidget,
    this.emptyWidget,
    this.padding,
    this.controller,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  State<LazyLoadingListView<T>> createState() => _LazyLoadingListViewState<T>();
}

class _LazyLoadingListViewState<T> extends State<LazyLoadingListView<T>> {
  late ScrollController _scrollController;
  StreamSubscription<LazyLoadingState<T>>? _subscription;
  LazyLoadingState<T>? _currentState;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    _scrollController.addListener(_onScroll);
    
    _subscription = widget.service.stateStream.listen((state) {
      if (mounted) {
        setState(() {
          _currentState = state;
        });
      }
    });

    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.service.loadInitial();
    });
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _scrollController.dispose();
    }
    _subscription?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      widget.service.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = _currentState;
    
    if (state == null) {
      return widget.loadingWidget ?? const Center(child: CircularProgressIndicator());
    }

    if (state.isEmpty && state.hasError) {
      return widget.errorWidget ?? Center(
        child: Text('Error: ${state.errorMessage}'),
      );
    }

    if (state.isEmpty) {
      return widget.emptyWidget ?? const Center(
        child: Text('No items found'),
      );
    }

    return RefreshIndicator(
      onRefresh: widget.service.refresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: widget.padding,
        shrinkWrap: widget.shrinkWrap,
        physics: widget.physics,
        itemCount: state.items.length + (state.isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < state.items.length) {
            return widget.itemBuilder(context, state.items[index], index);
          } else {
            return widget.loadingWidget ?? const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }
        },
      ),
    );
  }
}

/// Widget for lazy loading grids
class LazyLoadingGridView<T> extends StatefulWidget {
  final LazyLoadingService<T> service;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final SliverGridDelegate gridDelegate;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  final Widget? emptyWidget;
  final EdgeInsets? padding;
  final ScrollController? controller;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const LazyLoadingGridView({
    super.key,
    required this.service,
    required this.itemBuilder,
    required this.gridDelegate,
    this.loadingWidget,
    this.errorWidget,
    this.emptyWidget,
    this.padding,
    this.controller,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  State<LazyLoadingGridView<T>> createState() => _LazyLoadingGridViewState<T>();
}

class _LazyLoadingGridViewState<T> extends State<LazyLoadingGridView<T>> {
  late ScrollController _scrollController;
  StreamSubscription<LazyLoadingState<T>>? _subscription;
  LazyLoadingState<T>? _currentState;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    _scrollController.addListener(_onScroll);
    
    _subscription = widget.service.stateStream.listen((state) {
      if (mounted) {
        setState(() {
          _currentState = state;
        });
      }
    });

    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.service.loadInitial();
    });
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _scrollController.dispose();
    }
    _subscription?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      widget.service.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = _currentState;
    
    if (state == null) {
      return widget.loadingWidget ?? const Center(child: CircularProgressIndicator());
    }

    if (state.isEmpty && state.hasError) {
      return widget.errorWidget ?? Center(
        child: Text('Error: ${state.errorMessage}'),
      );
    }

    if (state.isEmpty) {
      return widget.emptyWidget ?? const Center(
        child: Text('No items found'),
      );
    }

    return RefreshIndicator(
      onRefresh: widget.service.refresh,
      child: CustomScrollView(
        controller: _scrollController,
        physics: widget.physics,
        shrinkWrap: widget.shrinkWrap,
        slivers: [
          SliverPadding(
            padding: widget.padding ?? EdgeInsets.zero,
            sliver: SliverGrid(
              gridDelegate: widget.gridDelegate,
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index < state.items.length) {
                    return widget.itemBuilder(context, state.items[index], index);
                  } else {
                    return widget.loadingWidget ?? const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                },
                childCount: state.items.length + (state.isLoading ? 1 : 0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
