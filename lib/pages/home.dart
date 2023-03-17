import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:loc/data/app_states.dart';
import 'package:loc/pages/arrival_list.dart';
import 'package:loc/pages/favorites_list.dart';
import 'package:loc/pages/reminders_search.dart';
import 'package:loc/pages/settings.dart';
import 'package:loc/pages/about.dart';
import 'package:loc/pages/reminders_add.dart';
import 'package:loc/utils/database_ops.dart';
import 'package:loc/utils/location.dart';
import 'package:loc/widgets/bottom_nav_bar.dart';
import 'package:loc/pages/reminders_list.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePage();
}

class _HomePage extends State<HomePage> with WidgetsBindingObserver {
  static const List<Widget> _navWidgetList = [
    RemindersList(),
    FavoritesList(),
    ArrivalList(),
    Settings(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<bool> didPopRoute() async {
    writeData(context);
    return false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        readData(context);
        break;
      case AppLifecycleState.paused:
        writeData(context);
        break;
      case AppLifecycleState.detached:
        writeData(context);
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appStates = Provider.of<AppStates>(context);

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (context.mounted) {
        if (appStates.listening == false) {
          getCurrentLocation().then((value) {
            appStates.setCurrent(value.position);
            handlePositionUpdates(context);
            appStates.setListening(true);
          });
        }

        if (appStates.loaded == false) {
          readData(context);
          appStates.setLoaded(true);
        }
      }
    });

    return WillPopScope(
      onWillPop: () async {
        if (appStates.selectedAll().isNotEmpty) {
          appStates.selectedClear();
          return false;
        }
        writeData(context);
        return true;
      },
      child: Stack(
        children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: 2,
              sigmaY: 2,
            ),
            child: Image.asset('assets/images/background.jpg'),
          ),
          Scaffold(
            backgroundColor:
                Theme.of(context).colorScheme.background.withOpacity(0.8),
            resizeToAvoidBottomInset: false,
            appBar: AppBar(
              actions: [
                appStates.selectedAll().isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          final selected = appStates.selectedAll();
                          for (int i = 0; i < selected.length; ++i) {
                            appStates.favoriteAdd(
                                appStates.reminderRead(id: selected[i])!.place);
                          }
                          appStates.selectedClear();
                        },
                        icon: const Icon(
                          Icons.favorite_rounded,
                          size: 32,
                        ),
                      )
                    : const SizedBox.shrink(),
                appStates.selectedAll().isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          final selected = appStates.selectedAll();
                          for (int i = 0; i < selected.length; ++i) {
                            appStates.reminderDelete(id: selected[i]);
                          }
                          appStates.selectedClear();
                        },
                        icon: const Icon(
                          Icons.delete_rounded,
                          size: 32,
                        ),
                      )
                    : const SizedBox.shrink(),
                appStates.selectedAll().isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          appStates.selectedClear();
                        },
                        icon: const Icon(
                          Icons.edit_rounded,
                          size: 32,
                        ),
                      )
                    : const SizedBox.shrink(),
                appStates.selectedAll().isNotEmpty
                    ? const SizedBox.shrink()
                    : appStates.bottomNavBarIndex == 0
                        ? IconButton(
                            onPressed: () {
                              Navigator.of(context).push<void>(
                                MaterialPageRoute<void>(
                                  builder: (context) {
                                    return const RemindersSearch();
                                  },
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.search_rounded,
                              size: 32,
                            ),
                          )
                        : const SizedBox.shrink(),
                appStates.selectedAll().isNotEmpty
                    ? const SizedBox.shrink()
                    : IconButton(
                        onPressed: () {
                          if (appStates.notify == true) {
                            FlutterRingtonePlayer.stop();
                            appStates.setRinging(false);
                            appStates.setNotify(false);
                          } else {
                            appStates.setNotify(true);
                          }
                        },
                        icon: Icon(
                          appStates.notify == true
                              ? Icons.alarm_on_rounded
                              : Icons.alarm_off_rounded,
                          color: appStates.notify == true
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(context).colorScheme.onTertiary,
                          size: 32,
                        ),
                      ),
                appStates.selectedAll().isNotEmpty
                    ? const SizedBox.shrink()
                    : IconButton(
                        onPressed: () {
                          Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                              builder: (context) {
                                return const AboutPage();
                              },
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.info_rounded,
                          size: 32,
                        ),
                      ),
              ],
              elevation: 0,
              leading: null,
              title: appStates.selectedAll().isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 32,
                      ),
                      onPressed: () {
                        appStates.selectedClear();
                      },
                    )
                  : const Text(
                      'Loc',
                    ),
            ),
            bottomNavigationBar: const AppBottomNavBar(),
            floatingActionButton: appStates.bottomNavBarIndex != 0
                ? null
                : FloatingActionButton(
                    elevation: 0,
                    onPressed: () {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (context) {
                            return const RemindersAdd();
                          },
                        ),
                      );
                    },
                    child: const Icon(
                      Icons.add_alarm_rounded,
                    ),
                  ),
            body: SafeArea(
              child: _navWidgetList.elementAt(appStates.bottomNavBarIndex),
            ),
          ),
        ],
      ),
    );
  }
}
