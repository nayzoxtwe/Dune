import { PrismaClient, UserRole } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  const adult = await prisma.user.upsert({
    where: { email: 'adult@example.com' },
    update: {},
    create: {
      email: 'adult@example.com',
      role: UserRole.adult,
      profile: { create: { displayName: 'Adulte Alpha' } },
      wallet: { create: { balance: 500 } }
    }
  });

  const teen = await prisma.user.upsert({
    where: { email: 'teen@example.com' },
    update: {},
    create: {
      email: 'teen@example.com',
      role: UserRole.teen,
      profile: { create: { displayName: 'Ado Beta' } },
      wallet: { create: { balance: 120 } }
    }
  });

  await prisma.parentalLink.upsert({
    where: { id: 'link' },
    update: {},
    create: {
      id: 'link',
      childId: teen.id,
      parentId: adult.id,
      nightStart: '23:00',
      nightEnd: '05:00'
    }
  });

  console.log('Seed complete');
}

main().finally(() => prisma.$disconnect());
