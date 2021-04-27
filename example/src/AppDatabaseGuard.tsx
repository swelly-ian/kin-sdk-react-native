import * as React from 'react';
import { FC, useState } from 'react';
import { db } from './db/app-database';

export const AppDatabaseGuard: FC = ({ children }) => {
  const [isReady, setIsReady] = useState<boolean>(false);

  if (!db.initialized) {
    db.init().then(setIsReady);
  }

  return isReady ? <>{children}</> : null;
};
