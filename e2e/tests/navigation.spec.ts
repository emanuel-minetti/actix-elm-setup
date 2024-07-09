import {expect, test} from "@playwright/test";

test.describe('navigation', () => {
    test('works from url', async ({ page }) => {
        await page.goto('http://localhost:8080/privacy');
        const content = page.locator('#content');
        const heading = content.getByRole('heading');
        await expect(heading).toHaveText(/Privacy Declaration/i);
        await expect(heading).not.toHaveText(/Imprint/i);

        await page.goto('http://localhost:8080/imprint');
        await expect(heading).toHaveText(/Imprint/i);
        await expect(heading).not.toHaveText(/Privacy Declaration/i);
    });

    test('works from navigation', async ({ page }) => {
        await page.goto('http://localhost:8080/');
        const footerElement = page.locator('footer');
        const privacyLink = footerElement.getByText(/Privacy/i);
        await privacyLink.click();
        const content = page.locator('#content');
        const heading = content.getByRole('heading');
        expect(page.url()).toContain('privacy');
        await expect(heading).toHaveText(/Privacy Declaration/i);
        await expect(heading).not.toHaveText(/Imprint/i);

        const imprintLink = footerElement.getByText(/Imprint/i);
        await imprintLink.click();
        expect(page.url()).toContain('imprint');
        await expect(heading).toHaveText(/Imprint/i);
        await expect(heading).not.toHaveText(/Privacy Declaration/i);
    });

    test('works with i18n on privacy', async ({ page }) => {
        await page.goto('http://localhost:8080/');
        const footerElement = page.locator('footer');
        const privacyLink = footerElement.getByText(/Privacy/i);
        const content = page.locator('#content');
        const heading = content.getByRole('heading');
        await privacyLink.click();
        expect(page.url()).toContain('privacy');
        await expect(heading).toHaveText(/Privacy Declaration/i);

        const headerElement = page.locator('header');
        const langSwitcher = headerElement.getByRole('combobox');
        await langSwitcher.selectOption({value: 'de'});
        await expect(heading).toHaveText(/Datenschutzerklärung/i);
    });

});