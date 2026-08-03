import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.checkroom_rounded,
                  size: 54,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'ClosetAI',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Build outfits, prep for trips, and keep your wardrobe organized with AI-powered assistance.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => context.go('/register'),
                icon: const Icon(Icons.rocket_launch_outlined),
                label: const Text('Create account'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => context.go('/login'),
                icon: const Icon(Icons.login_outlined),
                label: const Text('Sign in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
