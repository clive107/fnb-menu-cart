import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fnb_menu_cart/blocs/menu/menu_item_list/menu_item_list_bloc.dart';
import 'package:fnb_menu_cart/configs/themes/styles.dart';
import 'package:fnb_menu_cart/models/menu/menu_section.dart';
import 'package:fnb_menu_cart/utils/app/error_handling/get_failure_message.dart';
import 'package:fnb_menu_cart/utils/data_types/string.dart';
import 'package:fnb_menu_cart/widgets/common/error_view.dart';
import 'package:fnb_menu_cart/widgets/menu/menu_item_card.dart';
import 'package:fnb_menu_cart/widgets/order/cart_button.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(actions: const [CartButton()], title: const Text('Menu')),
      /* Section - BlocBuilder for MenuItemListBloc */
      body: BlocBuilder<MenuItemListBloc, MenuItemListState>(
        builder: (context, state) {
          final List<MenuSection>? menuSectionList = state.menuSectionList;
          // Nothing loaded yet: show the error with a retry, or a spinner.
          if (menuSectionList == null) {
            if (state.getMenuItemListStatus.isFailure) {
              return ErrorView(
                message: getFailureMessage(
                  failure: state.getMenuItemListFailure,
                ),
                onRetry: () => context.read<MenuItemListBloc>().add(
                  const GetMenuItemList(),
                ),
              );
            }
            return const Center(child: CircularProgressIndicator());
          }
          if (menuSectionList.isEmpty) {
            return const Center(child: Text('Nothing on the menu right now.'));
          }
          return _MenuSectionList(menuSectionList: menuSectionList);
        },
      ),
    );
  }
}

/// The menu, one sticky header and list per category. Items are built lazily
/// as they scroll into view.
class _MenuSectionList extends StatelessWidget {
  final List<MenuSection> menuSectionList;

  const _MenuSectionList({required this.menuSectionList});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final TextTheme textTheme = theme.textTheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.maxContentWidth),
        child: CustomScrollView(
          slivers: [
            for (final MenuSection menuSection in menuSectionList)
              // Groups a category's header with its items, so the pinned
              // header sticks only while its own items scroll past and the
              // next header pushes it away.
              SliverMainAxisGroup(
                slivers: [
                  /* Section - Category header */
                  PinnedHeaderSliver(
                    // Opaque, so cards don't show through behind the header
                    // while it's pinned.
                    child: ColoredBox(
                      color: colorScheme.surface,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.screenHorizontal,
                          AppSpacing.lg,
                          AppSpacing.screenHorizontal,
                          AppSpacing.sm,
                        ),
                        child: Text(
                          toSentenceCase(menuSection.category),
                          style: textTheme.titleMedium,
                        ),
                      ),
                    ),
                  ),
                  /* Section - Category items */
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenHorizontal,
                    ),
                    sliver: SliverList.separated(
                      itemCount: menuSection.menuItemList.length,
                      itemBuilder: (context, index) => MenuItemCard(
                        key: ValueKey<int>(menuSection.menuItemList[index].id),
                        menuItem: menuSection.menuItemList[index],
                      ),
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: AppSpacing.sm),
                    ),
                  ),
                ],
              ),
            /* Section - Bottom spacing */
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
          ],
        ),
      ),
    );
  }
}
