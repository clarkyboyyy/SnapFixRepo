import '../models/report.dart';

/// Seed data so the UI has something to render before a backend exists.
List<IssueReport> createSampleReports() => [
  IssueReport(
    id: 'SF-250101',
    title: 'Broken Streetlight',
    category: 'Street Lighting',
    description:
        'Two streetlights on Rizal Avenue have been out for a week, making the '
        'crosswalk unsafe after dark.',
    location: 'Rizal Avenue, Barangay San Isidro',
    status: 'Submitted',
    progress: 15,
    createdAt: DateTime(2026, 10, 21, 8, 15),
  ),
  IssueReport(
    id: 'SF-250102',
    title: 'Uncollected Garbage',
    category: 'Waste Management',
    description:
        'The pickup truck skipped our street for three days and the bins are '
        'overflowing onto the road.',
    location: 'Sampaguita Street, Barangay San Isidro',
    status: 'Submitted',
    progress: 10,
    createdAt: DateTime(2026, 10, 20, 17, 40),
  ),
  IssueReport(
    id: 'SF-250103',
    title: 'Flooded Crosswalk',
    category: 'Waterways & Drainage',
    description:
        'The drainage grate in front of the market is clogged, so the crossing '
        'floods every time it rains.',
    location: 'Market Crossing, Barangay San Isidro',
    status: 'Submitted',
    progress: 5,
    createdAt: DateTime(2026, 10, 22, 6, 5),
  ),
  IssueReport(
    id: 'SF-250104',
    title: 'Pothole on Mabini Street',
    category: 'Roads & Infrastructure',
    description:
        'A deep pothole near the junction is forcing motorcycles into the '
        'opposite lane.',
    location: 'Mabini Street, Barangay San Isidro',
    status: 'In Progress',
    progress: 60,
    createdAt: DateTime(2026, 10, 14, 9, 30),
  ),
  IssueReport(
    id: 'SF-250105',
    title: 'Overgrown Park Vegetation',
    category: 'Parks & Greenery',
    description:
        'Branches are blocking the pathway and the lights at the playground.',
    location: 'Plaza Park, Barangay San Isidro',
    status: 'Resolved',
    progress: 100,
    createdAt: DateTime(2026, 10, 3, 15, 0),
  ),
  IssueReport(
    id: 'SF-250106',
    title: 'Missing Manhole Cover',
    category: 'Public Safety',
    description:
        'An open maintenance hole on the sidewalk with no barrier around it.',
    location: 'Bonifacio Street, Barangay San Isidro',
    status: 'Resolved',
    progress: 100,
    createdAt: DateTime(2026, 9, 28, 11, 20),
  ),
];
