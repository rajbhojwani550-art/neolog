import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app.dart' show themeModeProvider;
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/babies/screens/baby_list_screen.dart';
import '../../features/babies/screens/baby_detail_screen.dart';
import '../../features/babies/screens/add_baby_screen.dart';
import '../../features/daily_log/screens/log_entry_screen.dart';
import '../../features/daily_log/screens/log_list_screen.dart';
import '../../features/growth/screens/growth_screen.dart';
import '../../features/screenings/rop/screens/rop_screen.dart';
import '../../features/screenings/ivh/screens/ivh_screen.dart';
import '../../features/screenings/echo/screens/echo_screen.dart';
import '../../features/screenings/hearing/screens/hearing_screen.dart';
import '../../features/screenings/nbs/screens/nbs_screen.dart';
import '../../features/screenings/mbd/screens/mbd_screen.dart';
import '../../features/medications/screens/medications_screen.dart';
import '../../features/events/screens/events_screen.dart';
import '../../features/investigations/screens/investigations_screen.dart';
import '../../features/discharge/screens/discharge_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/calendar/screens/calendar_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final isAuthRoute =
          state.matchedLocation == '/login' || state.matchedLocation == '/register';

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/patients',
            builder: (context, state) => const BabyListScreen(),
          ),
          GoRoute(
            path: '/calendar',
            builder: (context, state) => const CalendarScreen(),
          ),
          GoRoute(
            path: '/alerts',
            builder: (context, state) => const AlertsScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/baby/add',
        builder: (context, state) => const AddBabyScreen(),
      ),
      GoRoute(
        path: '/baby/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return BabyDetailScreen(babyId: id);
        },
        routes: [
          GoRoute(
            path: 'logs',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return LogListScreen(babyId: id);
            },
          ),
          GoRoute(
            path: 'logs/add',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return LogEntryScreen(babyId: id);
            },
          ),
          GoRoute(
            path: 'logs/:logId',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              final logId = state.pathParameters['logId']!;
              return LogEntryScreen(babyId: id, logId: logId);
            },
          ),
          GoRoute(
            path: 'growth',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return GrowthScreen(babyId: id);
            },
          ),
          GoRoute(
            path: 'rop',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return RopScreen(babyId: id);
            },
          ),
          GoRoute(
            path: 'ivh',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return IvhScreen(babyId: id);
            },
          ),
          GoRoute(
            path: 'echo',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return EchoScreen(babyId: id);
            },
          ),
          GoRoute(
            path: 'hearing',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return HearingScreen(babyId: id);
            },
          ),
          GoRoute(
            path: 'nbs',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return NbsScreen(babyId: id);
            },
          ),
          GoRoute(
            path: 'mbd',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return MbdScreen(babyId: id);
            },
          ),
          GoRoute(
            path: 'medications',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return MedicationsScreen(babyId: id);
            },
          ),
          GoRoute(
            path: 'events',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return EventsScreen(babyId: id);
            },
          ),
          GoRoute(
            path: 'investigations',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return InvestigationsScreen(babyId: id);
            },
          ),
          GoRoute(
            path: 'discharge',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return DischargeScreen(babyId: id);
            },
          ),
        ],
      ),
    ],
  );
});

class MainShell extends StatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const _routes = ['/dashboard', '/patients', '/calendar', '/alerts', '/settings'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          context.go(_routes[index]);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.child_care_outlined),
            activeIcon: Icon(Icons.child_care),
            label: 'Patients',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            activeIcon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alerts')),
      body: const _AlertsList(),
    );
  }
}

class _AlertsList extends StatelessWidget {
  const _AlertsList();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No pending alerts',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Overdue screenings and abnormal results\nwill appear here',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF1565C0),
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: const Text('Dr. User'),
              subtitle: const Text('Neonatologist'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Dark Mode'),
                  secondary: const Icon(Icons.dark_mode),
                  value: Theme.of(context).brightness == Brightness.dark,
                  onChanged: (value) {
                    ref.read(themeModeProvider.notifier).state =
                        value ? ThemeMode.dark : ThemeMode.light;
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.sync),
                  title: const Text('Sync Data'),
                  subtitle: const Text('Last synced: Never'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('About NeoLog'),
                  subtitle: const Text('Version 1.0.0'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFFC62828)),
              title: const Text('Logout',
                  style: TextStyle(color: Color(0xFFC62828))),
              onTap: () {
                ref.read(authStateProvider.notifier).logout();
                context.go('/login');
              },
            ),
          ),
        ],
      ),
    );
  }
}

