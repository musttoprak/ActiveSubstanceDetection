import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mobile/views/active_inredient_detail.dart';

import '../bloc/active_ingredient_bloc.dart';
import '../components/not_found.dart';
import '../models/response_models/active_ingredient_response_model.dart';

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
    searchFocusNode.dispose(); // Dispose the FocusNode
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
  late final Color backgroundColor;

  Scaffold buildScaffold(BuildContext context, ActiveIngredientState state) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: const Text("Etkin Maddeler"),
      ),
      body: SingleChildScrollView(
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
                      final query = searchController.text.trim();
                      if (query.isNotEmpty) {
                        context
                            .read<ActiveIngredientCubit>()
                            .searchActiveIngredient(query);
                      }
                    },
                  ),
                ),
                onSubmitted: (value) {
                  final query = searchController.text.trim();
                  if (query.isNotEmpty) {
                    context
                        .read<ActiveIngredientCubit>()
                        .searchActiveIngredient(query);
                  }
                },
              ),
            ),
            SizedBox(
              height: MediaQuery.sizeOf(context).height * .8,
              child: _buildStateWidget(state, context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStateWidget(ActiveIngredientState state, BuildContext context) {
    if (state is ActiveIngredientLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (state is ActiveIngredientLoaded) {
      if (state.results.isEmpty) {
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
      return _buildResultList(state.results);
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

  Widget _buildResultList(List<ActiveIngredientResponseModel> results) {
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final ActiveIngredientResponseModel ingredient = results[index];
        final String imageUrl = ingredient.image_src ??
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
                    fit:
                        BoxFit.cover, // Ensure the image fits within the bounds
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.broken_image,
                          size: 50, color: Colors.grey);
                    },
                  ),
          ),
          title: Text(ingredient.name),
          subtitle: Text(
            ingredient.general_info != null &&
                    ingredient.general_info!.length > 60
                ? "${ingredient.general_info!.substring(0, 60)}..."
                : ingredient.general_info ?? "...",
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
          onTap: () => context
              .read<ActiveIngredientCubit>()
              .searchActiveIngredient(item),
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
