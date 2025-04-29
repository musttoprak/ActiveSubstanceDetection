import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mobile/views/active_inredient/active_inredient_detail.dart';

import '../../bloc/active_ingredient_bloc.dart';
import '../../components/not_found.dart';
import '../../models/response_models/active_ingredient_response_model.dart';

class ActiveIngredientScreen extends StatefulWidget {
  final Color backgroundColor;

  const ActiveIngredientScreen({super.key, required this.backgroundColor});

  @override
  State<ActiveIngredientScreen> createState() => _ActiveIngredientScreenState();
}

class _ActiveIngredientScreenState extends State<ActiveIngredientScreen>
    with ActiveIngredientMixin {
  @override
  void initState() {
    backgroundColor = widget.backgroundColor;
    super.initState();
  }

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    scrollController.dispose(); // Dispose scrollController
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ActiveIngredientCubit(),
      child: BlocBuilder<ActiveIngredientCubit, ActiveIngredientState>(
        builder: (context, state) {
          return buildScaffold(context, state);
        },
      ),
    );
  }
}

mixin ActiveIngredientMixin {
  final searchController = TextEditingController();
  final searchFocusNode = FocusNode();
  final scrollController = ScrollController();
  late final Color backgroundColor;

  // Pagination control
  int currentPage = 1;
  bool isLoadingMore = false;
  bool hasReachedEnd = false;
  String lastSearchQuery = "";

  Scaffold buildScaffold(BuildContext context, ActiveIngredientState state) {
    // Attach scroll listener when scaffold is built
    _setupScrollListener(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: const Text(
          "Etkin Maddeler",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: searchController,
                focusNode: searchFocusNode,
                decoration: InputDecoration(
                  hintText: "Etkin Madde Ara",
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      _performSearch(context);
                    },
                  ),
                ),
                onSubmitted: (value) {
                  _performSearch(context);
                },
              ),
            ),
            Expanded(
              child: _buildStateWidget(state, context),
            ),
          ],
        ),
      ),
    );
  }

  void _setupScrollListener(BuildContext context) {
    // Remove previous listeners to avoid duplicates
    scrollController.removeListener(() {});

    scrollController.addListener(() {
      if (scrollController.position.pixels >=
              scrollController.position.maxScrollExtent - 200 &&
          !isLoadingMore &&
          !hasReachedEnd) {
        _loadMoreItems(context);
      }
    });
  }

  void _performSearch(BuildContext context) {
    final query = searchController.text.trim();
    if (query.isNotEmpty) {
      // Reset pagination when starting a new search
      currentPage = 1;
      hasReachedEnd = false;
      lastSearchQuery = query;

      context
          .read<ActiveIngredientCubit>()
          .searchActiveIngredient(query, page: currentPage, isNewSearch: true);
    } else {
      currentPage = 1;
      hasReachedEnd = false;
      lastSearchQuery = query;

      context
          .read<ActiveIngredientCubit>()
          .searchActiveIngredient(null, page: currentPage, isNewSearch: true);
    }
  }

  void _loadMoreItems(BuildContext context) {
    if (lastSearchQuery.isEmpty) return;

    setState(() {
      isLoadingMore = true;
    });

    currentPage++;

    context.read<ActiveIngredientCubit>().searchActiveIngredient(
        lastSearchQuery,
        page: currentPage,
        isNewSearch: false);
  }

  // Helper method to call setState within the mixin
  void setState(Function() fn) {
    fn();
  }

  Widget _buildStateWidget(ActiveIngredientState state, BuildContext context) {
    if (state is ActiveIngredientLoading && currentPage == 1) {
      return const Center(child: CircularProgressIndicator());
    } else if (state is ActiveIngredientLoaded) {
      // Update loading state
      if (isLoadingMore && !state.isLoadingMore) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            isLoadingMore = false;
          });
        });
      }

      // Check if we've reached the end
      if (state.hasReachedEnd != hasReachedEnd) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            hasReachedEnd = state.hasReachedEnd;
          });
        });
      }

      if (state.results.isEmpty && currentPage == 1) {
        return NotFoundScreen(
          title: "No Results Found",
          description:
              "We couldn't find any active ingredients matching your search. Try again with different keywords.",
          btnText: "Try Again",
          press: () {
            searchFocusNode.requestFocus();
          },
        );
      }
      return _buildResultList(state.results, state.isLoadingMore);
    } else if (state is SearchHistoryLoaded) {
      if (state.history.isEmpty) {
        return NotFoundScreen(
          title: "No Search History",
          description:
              "You don't have any search history yet. Try searching for an active ingredient.",
          btnText: "Search Now",
          press: () {
            searchFocusNode.requestFocus();
          },
        );
      }
      return _buildHistoryList(state.history, context);
    } else if (state is ActiveIngredientError) {
      return NotFoundScreen(
        title: "Error Occurred",
        description: state.message,
        btnText: "Retry",
        press: () {
          searchFocusNode.requestFocus();
        },
      );
    }
    return const Center(child: Text("Geçmiş Aramalarım"));
  }

  Widget _buildResultList(
      List<EtkenMaddeResponseModel> results, bool isLoadingMore) {
    return ListView.builder(
      controller: scrollController,
      itemCount: results.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Show loading indicator at the end when loading more items
        if (index == results.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final EtkenMaddeResponseModel ingredient = results[index];
        final String imageUrl = ingredient.resimUrl ??
            'https://static.tebrp.com/etkin_resim/etkinMaddeNoImg.svg';

        return ListTile(
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ActiveIngredientDetailPage(ingredient: ingredient),
                ));
          },
          leading: SizedBox(
            width: 50,
            height: 50,
            child: imageUrl.endsWith('.svg')
                ? SvgPicture.network(
                    imageUrl,
                    placeholderBuilder: (context) =>
                        const CircularProgressIndicator(),
                    fit: BoxFit.cover,
                  )
                : Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.broken_image,
                          size: 50, color: Colors.grey);
                    },
                  ),
          ),
          title: Text(ingredient.etkenMaddeAdi),
          subtitle: Text(
            ingredient.genelBilgi != null && ingredient.genelBilgi!.length > 60
                ? "${ingredient.genelBilgi!.substring(0, 60)}..."
                : ingredient.genelBilgi ?? "...",
          ),
        );
      },
    );
  }

  Widget _buildHistoryList(List<String> history, BuildContext context) {
    return ListView.builder(
      itemCount: history.length,
      itemBuilder: (context, index) {
        final item = history[index];
        return InkWell(
          onTap: () {
            searchController.text = item;
            _performSearch(context);
          },
          child: ListTile(
            title: Text(item),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                context.read<ActiveIngredientCubit>().deleteHistory(item);
              },
            ),
          ),
        );
      },
    );
  }
}
