FROM node:20-alpine AS builder

WORKDIR /app

COPY package.json yarn.lock ./
COPY packages/app/package.json ./packages/app/
COPY packages/database/package.json ./packages/database/
COPY packages/server/package.json ./packages/server/

RUN yarn install --frozen-lockfile

COPY . .

RUN yarn workspace @crest/database generate
RUN yarn workspace @crest/server build && yarn cache clean


FROM node:20-alpine AS production

WORKDIR /app

RUN addgroup -g 1001 -S nodejs
RUN adduser -S nestjs -u 1001

COPY package.json yarn.lock ./
COPY packages/app/package.json ./packages/app/
COPY packages/database/package.json ./packages/database/
COPY packages/server/package.json ./packages/server/

RUN yarn install --frozen-lockfile --production && yarn cache clean

COPY --chown=nestjs:nodejs packages/database ./packages/database
COPY --from=builder --chown=nestjs:nodejs /app/node_modules/.prisma ./node_modules/.prisma

COPY --from=builder --chown=nestjs:nodejs /app/packages/server/dist ./packages/server/dist

USER nestjs

EXPOSE 3000
CMD ["node", "packages/server/dist/main"]